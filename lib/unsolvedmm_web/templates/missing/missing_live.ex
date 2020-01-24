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
            {:first_name, "First Name"}, 
            {:middle_name, "Middle Name"}, 
            {:last_name, "Last Name"}, 
            {:nickname, "Nickname"}, 
            {:gender, "Gender"}, 
            {:race_ethnicity, "Ethnicity"},
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

    # def handle_event("sort", %{"col" => col, "action" => action}, socket) do
    #     rows = Unsolvedmm.missing()
    #         |> Enum.sort(fn(rec1, rec2) -> 
    #             case action do
    #                 "asc" -> Map.get(rec1, String.to_atom(col)) < Map.get(rec2, String.to_atom(col))
    #                 "des" -> Map.get(rec1, String.to_atom(col)) > Map.get(rec2, String.to_atom(col))
    #             end 
    #         end)
    #     {:noreply, assign(socket, :rows, rows)}
    # end

    def handle_event("reset_filter", filter, socket) do
        keys = Map.keys(filter)
        new_filter = for k <- keys, do: Map.replace!(filter, k, nil)
        rows = Unsolvedmm.missing()
        # TODO: clear fields etc.
        {:noreply, assign(socket, rows: rows, filter: new_filter)}
    end

    def handle_event("filter", filter, socket) do
        IO.inspect filter
        keys = Map.keys(filter)
        head_key = hd(Map.keys(filter))
        [head_val] = filter[head_key]

        new_filter = case head_val do
            "All" -> socket.assigns.filter |> Map.delete(head_key)
              _   -> socket.assigns.filter |> Map.merge(filter)
        end

        # TODO: pop the _target filter and run it last to give it priority?

        filter_rows = 
            Enum.reduce(keys, Unsolvedmm.missing(), fn 
                (x, acc) when x=="_target" -> acc
                (x, acc) ->
                    {type, field} = String.split_at(x, 3)
                    case is_nil(filter[x]) || filter[x] == "" do
                        true -> acc
                        false -> 
                            case type do
                                "sw_" -> sort(filter[x], acc, field)
                                "ac_" -> get_ac_filter_rows(acc, field, filter[x]) # autocomplete
                                "tg_" -> get_ac_filter_rows(acc, field, filter[x]) # toggle gender
                                _ -> acc
                            end
                    end
            end)
        {:noreply, assign(socket, rows: filter_rows, filter: new_filter)}
    end

    # def get_filter_rows(rows, key, value) do
    #     rows
    #     |> Enum.filter(fn x -> 
    #         String.starts_with?(Map.get(x, String.to_atom(key)), value)
    #     end)
    # end

    def sort(action, rows, key) do
        rows
        |> Enum.sort(fn(rec1, rec2) -> 
            case action do
                "asc" -> Map.get(rec1, String.to_atom(key)) < Map.get(rec2, String.to_atom(key))
                "des" -> Map.get(rec1, String.to_atom(key)) > Map.get(rec2, String.to_atom(key))
            end 
        end)
    end

    def get_ac_filter_rows(rows, _, nil), do: rows
    def get_ac_filter_rows(rows, _, ""), do: rows
    def get_ac_filter_rows(rows, nil, _), do: rows
    def get_ac_filter_rows(rows, "", _), do: rows
    def get_ac_filter_rows(rows, key, value) do
        rows
        |> Enum.filter(fn x -> 
            case Map.get(x, String.to_atom(key)) do
                nil -> x
                "" -> x
                good_val -> String.contains?(String.downcase(good_val), String.downcase(value))
                _ -> x
            end
            
        end)
    end

    def get_filter_list do
        ["first_name"]
    end

    def render(assigns) do
        ~L"""
        <div id="menu" class="menu">
            <div class="container">
                <div class="author-content">
                    <h4>Unsolved Search</h4>
                    <span>Missing</span>
                </div>

                <div class="filters-text">
                    <form phx-change="filter" style="margin-bottom: 5px !important;">
                        <%= for {col,title} <- @cols do %>
                            <%= if @show_cols[col]==="true" do %> 
                                <div class="filter-div">
                                <table id="filters" style="border: 0; margin-bottom: -1.5rem !important;"><tr>
                                <td>
                                <span class="filter-label"><%= title%></span> 
                                
                                    <%= if (col in @show_sort_arrows) do %> 
                                        <SELECT multiple class="input fancy" name="sw_<%= col %>">
                                            <option value="asc">&#xf062 A-Z</option>
                                            <option value="des">&#xf063 Z-A</i></option>
                                        </select>
                                    <% end %>
                                    <%= if (col == :gender) do %>  
                                        <SELECT class="input full-select" name="tg_gender">
                                            <option value=""></option>
                                            <option value="female">Female</option>
                                            <option value="male">Male</option>
                                            <option value="unsure">Non-binary</option>
                                            <option value="unknown">Unknown</option>
                                        </select>
                                    <% end %>
                                </td>
                                <td>
                                    <%= if (col in [:first_name, :middle_name, :last_name, :last_seen_city, :last_seen_state, :last_seen_county, :region]) do %>  
                                        <span class="filter-text">Contains &nbsp;<input type="text" class="input text" name="ac_<%= col %>" value="<%= @ac_entry %>" list="ac_matches" placeholder="Begin typing..." <%= if @ac_loading, do: "readonly" %>/></span> 
                                    <% end %>
                                
                                </td></tr></table>
                                </div>
                            <% end %>
                        <% end %>
                    </form>                    
                    <input type="button" phx-click="rest_filter" value="Reset Filters" class="btn btn-primary btn-sm">
                </div>

                <div class="display-columns"><span class="filter-label">Displayed Columns</span> </div>

                <form phx-change="show_cols">
                <ul class="display-columns">
                    <%= for {col,title} <- @cols do %>
                        <li><input name="<%= col %>" type="hidden" value="false">
                        <input type="checkbox" name="<%= col %>" value="true" <%= checked?(@show_cols[col]) %> ><%= title %></li>
                    <% end %>
                </ul>
                </form>
                
                <div class="copyright-text">
                    <p>Copyright 2020 Vanessa Lee<br></p>
                </div>
            </div>
        </div>

        <div id="contentbox" class="contentbox">

        <table id="missing" >
        <thead>
            <tr>
                <th colspan="4" scope="colgroup">Name</th>
                <th colspan="2" scope="colgroup"></th>
                <th colspan="7" scope="colgroup">Missing from . . . </th>
            </tr>
            <tr>
            <%= for {col,title} <- @cols do %>
                <%= if @show_cols[col]==="true" do %> 
                    <th nowrap>
                        <%= title %>
                        <%= if (col in @show_sort_arrows) do %> 
                            <a href="#" phx-click="filter" phx-value-col=<%= col %> phx-value-action="asc">&uarr;</a> 
                            <a href="#" phx-click="filter" phx-value-col=<%= col %> phx-value-action="des">&darr;</a> 
                        <% end %>
                    </th>
                <% end %>
            <% end %>
            </tr>
            <tr>
                <form phx-change="filter" style="margin-bottom: 5px !important;">
                    <%= for {col,title} <- @cols do %>
                        <%= if @show_cols[col]==="true" do %> 
                            <th nowrap>
                                <%= if (col in @show_sort_arrows) do %> 
                                    <span class="filter-label">sort</span> <SELECT class="input" name="sw_<%= col %>">
                                        <option value=""> </option>
                                        <option value="asc">A->Z</option>
                                        <option value="des">Z->A</option>
                                    </select>
                                <% end %>
                                <%= if (col == :gender) do %>  
                                    <SELECT class="input" name="tg_gender">
                                        <option value=""> </option>
                                        <option value="female">Female</option>
                                        <option value="male">Male</option>
                                        <option value="unsure">Non-binary</option>
                                        <option value="unknown">Unknown</option>
                                    </select>
                                <% end %>
                                <%= if (col in [:first_name, :middle_name, :last_name, :last_seen_city, :last_seen_state, :last_seen_county, :region]) do %>  
                                    <br/><span class="filter-label">contains <input type="text" class="input text" name="ac_<%= col %>" value="<%= @ac_entry %>" list="ac_matches" placeholder="Begin typing..." <%= if @ac_loading, do: "readonly" %>/></span> 
                                <% end %>
                            </th>
                        <% end %>
                    <% end %>
                </form>
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
        </div>
        """
        # MissingView.render("missing.html", assigns)
    end
end