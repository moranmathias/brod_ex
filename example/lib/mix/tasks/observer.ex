defmodule Mix.Tasks.Observer do
  def run(_) do
    Application.ensure_all_started(:example)
    :observer.start()
    Process.sleep(:infinity)
  end
end
