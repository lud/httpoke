defmodule Httpoke.Request do
  alias __MODULE__

  @enforce_keys [:__no_litteral__]
  defstruct headers: [],
            url: nil,
            method: nil,
            assigns: %{},
            dispatcher: nil

  @methods ~w(get post put patch delete options head)a

  defguard is_method(method) when method in @methods
  defguard is_url(url) when is_binary(url) or is_struct(url, URI)

  defguard is_dispatcher(dispatcher)
           when (is_atom(dispatcher) and nil != dispatcher) or
                  is_function(dispatcher, 1)

  def new(opts \\ []) do
    Enum.reduce(opts, Request.__struct__(), &init_opt/2)
  end

  ##
  ## 
  ##

  defp init_opt({:method, method}, %Request{} = req) when is_method(method) do
    put_method(req, method)
  end

  defp init_opt({:url, url}, %Request{} = req) when is_url(url) do
    put_url(req, url)
  end

  defp init_opt({:dispatcher, dispatcher}, %Request{} = req) when is_dispatcher(dispatcher) do
    put_dispatcher(req, dispatcher)
  end

  defp init_opt(other, _) do
    raise ArgumentError, message: "invalid #{__MODULE__} option: #{inspect(other)}"
  end

  ##
  ## 
  ##

  defp put_url(%Request{} = req, url) when is_url(url) do
    %Request{req | url: URI.parse(url)}
  end

  defp put_method(%Request{} = req, method) when is_method(method) do
    %Request{req | method: method}
  end

  defp put_dispatcher(%Request{} = req, dispatcher) when is_dispatcher(dispatcher) do
    %Request{req | dispatcher: dispatcher}
  end

  def merge_path(%Request{url: nil}, path) when is_binary(path) do
    raise ArgumentError, message: "cannot merge path as base url is not set"
  end

  def merge_path(%Request{url: %URI{} = url} = req, path) when is_url(path) do
    %Request{req | url: URI.merge(url, path)}
  end

  def dispatch(%Request{} = req) do
    case validate(req) do
      {:ok, _req} -> dispatch(req, req.dispatcher)
      {:error, _} = err -> err
    end
  end

  @doc false
  def dispatch(%Request{} = req, dispatcher) when is_atom(dispatcher) do
    dispatcher.dispatch(req)
  end

  def dispatch(%Request{} = req, dispatcher) when is_function(dispatcher, 1) do
    dispatcher.(req)
  end

  @validators [:url, :method, :dispatcher]

  def validate(req) do
    Enum.reduce(@validators, {:ok, req}, &validate_loop/2)
  end

  defp validate_loop(validator, {:ok, req}) do
    validate(validator, req)
  end

  defp validate_loop(_validator, {:error, _} = err) do
    err
  end

  defp validate(:url, %Request{url: url} = req) do
    case url do
      %URI{} -> {:ok, req}
      nil -> {:error, "the url is not set"}
      invalid -> {:error, "invalid url #{inspect(invalid)}"}
    end
  end

  defp validate(:method, %Request{method: method} = req) do
    case method do
      m when m in @methods -> {:ok, req}
      nil -> {:error, "the method is not set"}
      invalid -> {:error, "invalid method #{inspect(invalid)}"}
    end
  end

  defp validate(:dispatcher, %Request{dispatcher: dispatcher} = req) do
    case dispatcher do
      d when is_dispatcher(d) -> {:ok, req}
      nil -> {:error, "the dispatcher is not set"}
      invalid -> {:error, "invalid dispatcher #{inspect(invalid)}"}
    end
  end

  defp validate(other, %Request{} = _req) do
    raise ArgumentError, message: "unknown request validator #{inspect(other)}"
  end
end
