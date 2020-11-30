defmodule Gemini.Server do
  use GenServer

  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(args) do
    port = Keyword.get(args, :port, 1965)

    {:ok, listen_socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")

    accept_connections(listen_socket)
  end

  defp accept_connections(listen_socket) do
    {:ok, socket} = :gen_tcp.accept(listen_socket)

    {:ok, pid} =
      Task.Supervisor.start_child(
        Gemini.RequestSupervisor,
        fn -> serve(socket) end
      )

    :ok = :gen_tcp.controlling_process(socket, pid)

    accept_connections(listen_socket)
  end

  defp serve(socket) do
    socket
    |> read_line()
    |> write_line(socket)

    serve(socket)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)

    Logger.info data

    data
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end
end
