defmodule Questie.Response do
  alias Questie.Response.Adapter

  def get_status(response) do
    Adapter.get_status(response)
  end

  def expect_status(response, expected) when is_integer(expected) do
    case get_status(response) do
      ^expected -> {:ok, expected}
      status -> {:error, {__MODULE__, :bad_status, status: status, expected: expected}}
    end
  end

  def expect_status(response, from..to = range) do
    status = get_status(response)

    if status in range do
      {:ok, status}
    else
      {:error, {__MODULE__, :bad_status, status: status, expected: range}}
    end
  end
end

defprotocol Questie.Response.Adapter do
  def get_status(response)
end
