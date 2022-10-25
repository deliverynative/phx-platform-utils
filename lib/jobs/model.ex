defmodule PhxPlatformUtils.Jobs.Model do
  use Ecto.Schema
  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  import Ecto.Changeset

  # Add success column

  schema "job_executions" do
    field(:attempt, :integer)
    field(:completed_at, :utc_datetime_usec)
    field(:encoded_parameters, :string)
    field(:hash, :string)
    field(:job_name, :string)
    field(:succeeded, :boolean)
    timestamps()
  end

  @doc false
  def changeset(job_execution, attrs) do
    job_execution
    |> cast(attrs, [:attempt, :completed_at, :encoded_parameters, :hash, :job_name, :succeeded])
    |> validate_required([:attempt, :encoded_parameters, :job_name])
    |> unique_constraint([:hash, :attempt])
  end
end
