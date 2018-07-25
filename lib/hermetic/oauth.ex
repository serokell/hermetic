defmodule Hermetic.OAuth do
  def bearer(token) do
    {"authorization", "Bearer " <> token}
  end
end
