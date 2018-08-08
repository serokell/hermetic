defmodule Hermetic.OAuth do
  @doc """
    Turn OAuth 2.0 Bearer token into HTTP Authorization header tuple.

    See: <https://oauth.net/2/bearer-tokens/>
  """
  @spec bearer(String.t()) :: {String.t(), String.t()}
  def bearer(token) do
    {"authorization", "Bearer " <> token}
  end
end
