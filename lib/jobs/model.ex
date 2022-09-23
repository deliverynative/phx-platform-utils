defmodule PhxPlatformUtils.Jobs.Model do
  use Ecto.Schema
  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  import Ecto.Changeset

  schema "job_executions" do
    field(:completed_at, :utc_datetime_usec)
    field(:encoded_parameters, :string)
    field(:hash, :string)
    field(:job_name, :string)
    timestamps()
  end

  @doc false
  def changeset(job_execution, attrs) do
    job_execution
    |> cast(attrs, [:completed_at, :encoded_parameters, :hash, :job_name])
    |> validate_required([:encoded_parameters, :job_name])
  end
end
