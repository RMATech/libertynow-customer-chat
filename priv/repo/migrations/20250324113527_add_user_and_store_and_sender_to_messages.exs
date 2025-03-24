defmodule LiveviewChat.Repo.Migrations.AddUserAndStoreAndSenderToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      # add :user_id, :string
      # add :store_id, :string
      add :sender_type, :string
    end
  end
end
