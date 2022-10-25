defmodule PhxPlatformUtils.Jobs.Base do
  alias PhxPlatformUtils.Jobs.Model
  alias PhxPlatformUtils.Utils.RequestHelpers

  @moduledoc """
    Base module for all jobs.
    You MUST define the following functions:

    ## execute/1 - The function to execute on enquement
        Map.t()) :: :ok | {:error, any()}


    ## lock_params/1 - How this job should be locked
        (Map.t()) :: Map.t() | nil

  """

  @doc """
    Return a set of enquement parameters to serve as a unique job lock identifier
    If no lock is required, return an empty Map.
    Parameters may also be mutated to determine the lock state.
    Mutating parameters in the lock_params function will not mutate the execution parameters.

    Must return take and return a single Map. Do not include `:job_name` as a lock parameter, it will be ignored.

    ## Examples
      # Lock this job based on the :order_id parameter.
      def lock_params(params) do
        params
        |> Map.take([:order_id])
      end

      # Don't lock this job.
      def lock_params(_params), do: %{}

      # Lock this job based on a mutated date parameter.any()
      def lock_params(%{ occurred_at: occurred_at, types }) do
        date = DateTime.to_date(occurred_at)
        %{ date: date, types: types }
      end

  """
  @callback lock_params(Map.t()) :: Map.t()

  @doc """
    This is the actual job execution function. It will be called with the parameters that the job is enqueued with. These must be a map.

    ## Example
      def execute(%{ order_id: order_id }) do
        MyFunctions.do_it(order_id)
      end
  """
  @callback execute(Map.t()) :: :ok | {:error, any()}

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @job_name Keyword.fetch!(opts, :name)
      @repo Keyword.fetch!(opts, :repo)
      # @behaviour behaviour
      require Logger

      def log_for_job(message, level \\ :info) do
        %{jid: exq_job_id} = Exq.worker_job()
        message = "#{__MODULE__}[#{exq_job_id}]: #{message}"

        case level do
          :debug -> Logger.debug(message)
          :error -> Logger.error(message)
          :info -> Logger.info(message)
          :warn -> Logger.warn(message)
          _ -> Logger.info(message)
        end
      end

      def get_active_execution_lock_for_hash(hash) do
        Model
        |> where([m], m.hash == ^hash)
        |> where([m], is_nil(m.completed_at))
        |> first()
        |> unquote(@repo).one()
      end

      def get_latest_execution_for_hash(hash) do
        Model
        |> where([m], m.hash == ^hash)
        |> order_by(desc: :completed_at)
        |> first()
        |> unquote(@repo).one()
      end

      def insert_execution_lock(hash, encoded_params, attempt) do
        unquote(@repo).insert!(%Model{
          attempt: attempt,
          hash: hash,
          encoded_parameters: encoded_params,
          job_name: unquote(@job_name)
        })
      end

      def update_execution(execution_record, attrs \\ %{}) do
        execution_record
        |> Model.changeset(attrs)
        |> unquote(@repo).update!()
      end

      def get_hash(locked_params) do
        param_binary =
          locked_params
          |> Map.put(:job_name, unquote(@job_name))
          |> Map.to_list()
          |> Enum.sort()
          |> :erlang.term_to_binary()

        hash = :crypto.hash(:sha256, param_binary) |> Base.encode64()

        {:ok, hash}
      end

      def encode_params(params) do
        params
        |> Map.to_list()
        |> Enum.sort()
        |> :erlang.term_to_binary()
        |> Base.encode64()
      end

      def execution_locked_with_param_hash(params) do
        with locked_params <- lock_params(params),
             false <- is_nil(locked_params) || Enum.empty?(locked_params),
             {:ok, hash} <- get_hash(locked_params) do
          active_execution = get_active_execution_lock_for_hash(hash)
          {active_execution, hash}
        else
          true ->
            log_for_job("#{__MODULE__}.lock_params/1 did not return a lockable state, skipping to execute/1.")
            {false, nil}
        end
      end

      def perform(params) do
        try do
          atomized_params = params |> RequestHelpers.recursively_atomize()
          log_for_job("determining lock state.")
          {locker_record, hash} = execution_locked_with_param_hash(atomized_params)

          if locker_record, do: raise(:locked)

          previous_execution = get_latest_execution_for_hash(hash)

          attempt_number = if previous_execution != nil, do: Map.get(previous_execution, :attempt) + 1, else: 1

          encoded_params = atomized_params |> encode_params()

          with %Model{} = inserted_record <- insert_execution_lock(hash, encoded_params, attempt_number) do
            execute(atomized_params)
            update_execution(inserted_record, %{completed_at: DateTime.utc_now(), succeeded: true})
            log_for_job("id: #{inserted_record.id}]: execution successfully completed.")
          end
        rescue
          Ecto.ConstraintError ->
            log_for_job("execution locked by another process.")
            nil

          :locked ->
            log_for_job("execution locked by another process.")
            nil

          err ->
            log_for_job("execution failed with unexpected error: #{inspect(err)}", :error)
            raise err
        end
      end
    end
  end
end
