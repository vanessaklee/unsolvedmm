defmodule UnsolvedmmWeb.MissingLive do
use Phoenix.LiveView
alias UnsolvedmmWeb.MissingView

    def checked?(value) do
        case value do
            "true" -> "checked"
            "false" -> ""
            _ -> ""
        end
    end

    def mount(_session, socket) do
        rows = Unsolvedmm.missing()
        cols = [
            {:first_name, "First"}, 
            {:middle_name, "Middle"}, 
            {:last_name, "Last"}, 
            {:nickname, "Nickname"}, 
            {:gender, "Gender"}, 
            {:race_ethnicity, "Race/Ethnicity"},
            {:last_seen_date, "Date"}, 
            {:last_seen_age, "Age"}, 
            {:last_seen_city, "City"}, 
            {:last_seen_state, "State"}, 
            {:last_seen_county, "County"}, 
            {:region, "Region"}, 
            {:years_missing, "How long?"}
        ]
        show_cols = Enum.map(cols, fn {col,_} -> {col,"true"} end) |> Enum.into(%{}) |> Map.put(:nickname, "false") |> Map.put(:middle_name, "false")
        {:ok, assign(socket, rows: rows, show_cols: show_cols, cols: cols, mode: :hide_filters, filter: %{}, ac_loading: false, ac_matches: [], ac_entry: "" )}
        # {:ok, assign(socket, missing: missing)}
    end

    def handle_event("show_cols", string_checked_cols , socket) do
        checked_cols = for {key, val} <- string_checked_cols, into: %{}, do: {String.to_atom(key), val}
        {:noreply, assign(socket, show_cols: checked_cols)}
    end

    def handle_event("toggle-mode", _, socket) do
        {:noreply,
         update(socket, :mode, fn
           :show_filters -> :hide_filters
           :hide_filters -> :show_filters
        end)}
    end

    def handle_event("sort", %{"col" => col, "action" => action}, socket) do
        rows = Unsolvedmm.missing()
            |> Enum.sort(fn(rec1, rec2) -> 
                case action do
                    "asc" -> Map.get(rec1, String.to_atom(col)) < Map.get(rec2, String.to_atom(col))
                    "des" -> Map.get(rec1, String.to_atom(col)) > Map.get(rec2, String.to_atom(col))
                end 
            end)
        {:noreply, assign(socket, :rows, rows)}
    end

    def handle_event("filter", filter, socket) do
        IO.inspect "filter et al"
        IO.inspect filter


        key = hd(Map.keys(filter))
        val = filter[key]
        IO.inspect key
        IO.inspect val


        new_filter = case val do
            "All" -> socket.assigns.filter |> Map.delete(key)
              _   -> socket.assigns.filter |> Map.merge(filter)
        end

        [value] = val

        IO.inspect "-------"
        IO.inspect filter[value]

        filter_rows = get_filter_rows(value, filter[value])

        {:noreply, assign(socket, rows: filter_rows, filter: new_filter)}
        # {:noreply, assign(socket, :rows, Unsolvedmm.missing() )}
    end

    def handle_event("suggest", %{"ac" => ac}, socket) when byte_size(ac) <= 100 do
        ac_matches = get_ac_filter_rows("first_name", ac)
        {:noreply, assign(socket, rows: ac_matches)}
    end

    def get_filter_rows(key, value) do
        Unsolvedmm.missing()
        |> Enum.filter(fn x -> 
            String.starts_with?(Map.get(x, String.to_atom(key)), value)
        end)
    end

    def get_ac_filter_rows(key, value) do
        Unsolvedmm.missing()
        |> Enum.filter(fn x -> 
            String.contains?(String.downcase(Map.get(x, String.to_atom(key))), String.downcase(value))
        end)
    end

    def get_filter_list do
        ["first_name"]
    end

    def render(assigns) do
        ~L"""
        <form phx-change="show_cols">
            <%= for {col,title} <- @cols do %>
                <input name="<%= col %>" type="hidden" value="false">
                <input type="checkbox" name="<%= col %>" value="true" <%= checked?(@show_cols[col]) %> ><%= title %>
            <% end %>
        </form>

        <%= if @mode == :hide_filters do %>
            <input type="hidden" phx-click="toggle-mode" value="Show filters">
        <% else %>
            <input type="hidden" phx-click="toggle-mode" value="Hide filters">
        <% end %>

        <table id="missing" >
        <thead>
            <tr>
                <th colspan="4" scope="colgroup">Name</th>
                <th colspan="2" scope="colgroup"></th>
                <th colspan="7" scope="colgroup">Went Missing</th>
            </tr>
            <tr>
            <%= for {col,title} <- @cols do %>
                <%= if @show_cols[col]==="true" do %> 
                    <th>
                        <%= title %>
                        <%= if (col in [:first_name, :middle_name, :last_name, :race_ethnicity, :last_seen_age, :last_seen_city, :last_seen_state, :last_seen_county, :region, :years_missing]) do %> 
                            <a href="#" phx-click="sort" phx-value-col=<%= col %> phx-value-action="asc">&uarr;</a> 
                            <a href="#" phx-click="sort" phx-value-col=<%= col %> phx-value-action="des">&darr;</a> 
                        <% end %>
                        <%= if (col in [:first_name, :middle_name, :last_name, :last_seen_city, :last_seen_state, :last_seen_county, :region]) do %>
                            <form phx-change="filter">
                                <span class="filter-label">starts with</span>
                                <SELECT name="<%= col %>">
                                <option value=""> </option>
                                <%= for letter <- ?A..?Z do %>
                                    <option value=<%= << letter :: utf8 >> %>><%= << letter :: utf8 >> %></option>
                                <% end %>
                                </SELECT>
                            </form>
                        <% end %>
                        <%= if col in [:first_name] do %>
                            <form phx-change="suggest" phx-value-col="<%= col %>">
                                <input type="text" name="ac" value="<%= @ac_entry %>" list="ac_matches" placeholder="Begin typing..."
                                    <%= if @ac_loading, do: "readonly" %>/>
                                <datalist id="ac_matches">
                                <%= for ac_match <- @ac_matches do %>
                                    <option value="<%= ac_match %>"><%= ac_match %></option>
                                <% end %>
                                </datalist>
                            </form>

                        <% end %>
                    </th>
                <% end %>
            <% end %>
            </tr>
        </thead>
        <tbody>
            <%= for row <- @rows do %>
            <tr>
                <%= for {col,_title} <- @cols do %>
                <%= if @show_cols[col]=="true" do %>
                    <td><%= Map.get(row,col) %></td>
                <% end %>
                <% end %>
            </tr>
            <% end %>
        </tbody>
        </table>
        """
        # MissingView.render("missing.html", assigns)
    end
end