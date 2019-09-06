defmodule UnsolvedmmWeb.MissingLive do
use Phoenix.LiveView
alias UnsolvedmmWeb.MissingView

    def mount(_session, socket) do
        {:ok, assign(socket, missing: Unsolvedmm.missing())}
    end

    def render(assigns) do
        MissingView.render("missing.html", assigns)
    end
end