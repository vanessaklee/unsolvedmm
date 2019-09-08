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
        show_sort_arrows = [:first_name, :middle_name, :last_name, :race_ethnicity, :last_seen_age, :last_seen_city, :last_seen_state, :last_seen_county, :region, :years_missing]
        show_cols = Enum.map(cols, fn {col,_} -> {col,"true"} end) |> Enum.into(%{}) |> Map.put(:nickname, "false") |> Map.put(:middle_name, "false")
        
        {:ok, assign(socket, 
            rows: rows, 
            show_cols: show_cols, 
            cols: cols, 
            filter: %{}, 
            ac_loading: false, 
            ac_matches: [], 
            ac_entry: "", 
            show_sort_arrows: show_sort_arrows 
        )}
    end

    def handle_event("show_cols", string_checked_cols , socket) do
        checked_cols = for {key, val} <- string_checked_cols, into: %{}, do: {String.to_atom(key), val}
        {:noreply, assign(socket, show_cols: checked_cols)}
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
        keys = Map.keys(filter)
        head_key = hd(Map.keys(filter))
        [head_val] = filter[head_key]

        new_filter = case head_val do
            "All" -> socket.assigns.filter |> Map.delete(head_key)
              _   -> socket.assigns.filter |> Map.merge(filter)
        end

        filter_rows = 
            Enum.reduce(keys, Unsolvedmm.missing(), fn 
                (x, acc) when x=="_target" -> acc
                (x, acc) ->
                    case is_nil(filter[x]) || filter[x] == "" do
                        true -> acc
                        false -> 
                            case x do
                                "ac_first_name" -> get_ac_filter_rows(acc, "first_name", filter[x]) # autocomplete
                                "sw_first_name" -> get_filter_rows(acc, "first_name", filter[x]) # filter by beginning letter
                                _ -> acc
                            end
                    end
            end)
        {:noreply, assign(socket, rows: filter_rows, filter: new_filter)}
    end

    def handle_event("suggest", %{"ac" => ac}, socket) when byte_size(ac) <= 100 do
        # ac_matches = get_ac_filter_rows("first_name", ac)
        # {:noreply, assign(socket, rows: ac_matches)}
    end

    def get_filter_rows(rows, key, value) do
        rows
        |> Enum.filter(fn x -> 
            String.starts_with?(Map.get(x, String.to_atom(key)), value)
        end)
    end

    def get_ac_filter_rows(rows, key, value) do
        rows
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
                        <%= if (col in @show_sort_arrows) do %> 
                            <a href="#" phx-click="sort" phx-value-col=<%= col %> phx-value-action="asc">&uarr;</a> 
                            <a href="#" phx-click="sort" phx-value-col=<%= col %> phx-value-action="des">&darr;</a> 
                        <% end %>
                        <%= if (col in [:first_name, :middle_name, :last_name, :last_seen_city, :last_seen_state, :last_seen_county, :region]) do %>
                            <form phx-change="filter" style="margin-bottom: 5px !important;">
                                <span class="filter-label">starts with</span>
                                <SELECT class="input" name="sw_<%= col %>"1>
                                <option value=""> </option>
                                <%= for letter <- ?A..?Z do %>
                                    <option value=<%= << letter :: utf8 >> %>><%= << letter :: utf8 >> %></option>
                                <% end %>
                                <input type="text" class="input" name="ac_first_name" value="<%= @ac_entry %>" list="ac_matches" placeholder="Begin typing..."
                                    <%= if @ac_loading, do: "readonly" %>/>
                                <datalist id="ac_matches">
                                <%= for ac_match <- @ac_matches do %>
                                    <option value="<%= ac_match %>"><%= ac_match %></option>
                                <% end %>
                                </datalist>
                                </SELECT>
                            </form>
                        <% end %>
                        <%= if col in [:first_name] do %>
                            <form class="ac_form" style="margin-bottom: 5px !important;" phx-change="suggest" phx-value-col="<%= col %>">
                                <input type="text" class="input" name="ac" value="<%= @ac_entry %>" list="ac_matches" placeholder="Begin typing..."
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