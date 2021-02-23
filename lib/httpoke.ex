defmodule Httpoke do
  alias __MODULE__.Request

  def request(opts \\ []) do
    Request.new(opts)
  end

  defdelegate merge_path(req, path), to: Request
  defdelegate dispatch(req), to: Request
end
