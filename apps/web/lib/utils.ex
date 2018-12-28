defmodule Utils do
  def log(val, e) do
    IO.puts("#{e.file}:#{e.line}: #{DateTime.utc_now()}")
    val
  end
end
