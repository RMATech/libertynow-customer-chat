defmodule LiveviewChat.Repo.Migrations.AddUserAndStoreIdToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :user_id, :string
      add :store_id, :string
    end
  end
end
