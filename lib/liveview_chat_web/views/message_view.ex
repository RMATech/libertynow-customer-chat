defmodule LiveviewChatWeb.MessageView do
  use LiveviewChatWeb, :view
  import Timex

  def format_datetime(nil), do: ""

  def format_datetime(dt) do
    Timex.format!(dt, "{YYYY}-{0M}-{0D} {h12}:{0m} {AM}")
  end
end
