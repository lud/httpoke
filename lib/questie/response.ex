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

  def get_header(response, name) when is_binary(name) do
    list = get_headers(response)
    :proplists.get_value(name, list, nil)
  end

  def get_headers(response) do
    Adapter.get_headers(response)
  end

  def get_body(response) do
    Adapter.get_body(response)
  end

  def decode_body(response, decode) when is_function(decode, 1) do
    body = Adapter.get_body(response)
    body = decode.(body)
    {:ok, Adapter.put_body(response, body)}
  end

  def decode_body(response, decode, opts) when is_function(decode, 2) do
    decode_body(response, fn body -> decode.(body, opts) end)
  end
end

defprotocol Questie.Response.Adapter do
  def get_status(response)

  # must return a list
  def get_headers(response)

  def get_body(response)

  def put_body(response, body)
end
