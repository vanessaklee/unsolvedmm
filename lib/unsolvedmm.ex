Application.ensure_all_started(:hound)

defmodule Unsolvedmm.Missing do
  use Memento.Table, attributes: [:id, :first_name, :middle_name, :last_name, :nickname, :gender, :last_seen_date, :last_seen_age, :last_seen_city, :last_seen_state, :last_seen_county, :region, :race_ethnicity, :years_missing]
end

defmodule Unsolvedmm do
  @moduledoc """
  Unsolvedmm keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  use Hound.Helpers
  alias :mnesia, as: Mnesia

  @regions nil

  def missing() do
    # Mnesia.create_schema([node()])
    # Mnesia.start()

    # TODO handle failures
    # TODO display failures?
    # TODO compare missing to unidentified
    # namus = parse_namus(namus_data())
    # lost = parse_lost(lost_data())
    # charley = parse_charley(charley_data())

    # full = namus ++ lost
    # full = namus
    # sorted = Enum.sort_by(full, fn f -> Map.get(f, "last_name") end)

    # case Mnesia.create_table(Missing, [attributes: [:id, :first_name, :middle_name, :last_name, :nickname, :gender, :last_seen_date, :last_seen_age, :last_seen_city, :last_seen_state, :last_seen_county, :region, :race_ethnicity, :years_missing]]) do 
    #   {:atomic, :ok} -> write_data(sorted)
    #     sorted
    #   {:aborted, {:already_exists, Missing}} -> read_data()
    #   _ -> %{} #TODO send human readable error message
    # end

    case Memento.Table.create(Unsolvedmm.Missing) do
      :ok -> 
        full = parse_namus(namus_data())
        sorted = Enum.sort_by(full, fn f -> Map.get(f, "last_name") end)
        write_data(sorted)
      {:error, {:already_exists, Unsolvedmm.Missing}} -> 
        case read_data() do
          [] -> 
            full = parse_namus(namus_data())
            sorted = Enum.sort_by(full, fn f -> Map.get(f, "last_name") end)
            write_data(sorted)
          data -> data
        end
      _ -> [] #TODO send human readable error message
    end
  end

  def write_data(datum) do
    Memento.transaction! fn ->
      for data <- datum do
        Memento.Query.write(
          %Unsolvedmm.Missing{
            id: data.id, 
            first_name: data.first_name,
            middle_name: data.middle_name,
            last_name: data.last_name,
            nickname: data.nickname, 
            gender: data.gender, 
            last_seen_date: data.last_seen_date, 
            last_seen_age: data.last_seen_age, 
            last_seen_city: data.last_seen_city, 
            last_seen_state: data.last_seen_state, 
            last_seen_county: data.last_seen_county, 
            region: data.region, 
            race_ethnicity: data.race_ethnicity, 
            years_missing: data.years_missing
          }
        )
      end
    end
    # Mnesia.transaction(fn ->Mnesia.write({Missing,
    #   data.id,
    #   data.first_name,
    #   data.middle_name,
    #   data.last_name,
    #   data.nickname, 
    #   data.gender, 
    #   data.last_seen_date, 
    #   data.last_seen_age, 
    #   data.last_seen_city, 
    #   data.last_seen_state, 
    #   data.last_seen_county, 
    #   data.region, 
    #   data.race_ethnicity, 
    #   data.years_missing
    # }) end)
  end

  def read_data() do 
    # {_, data} = Mnesia.transaction(fn ->:mnesia.match_object({Missing, :_, :_}) end)
    # data
    Memento.transaction! fn -> Memento.Query.all(Unsolvedmm.Missing) end
  end

  def parse_namus(results) do
    data = Map.get(results, "results")

    Enum.map(data, fn r ->
      state = Map.get(r, "stateDisplayNameOfLastContact")

      ethnicity =
        case is_list(Map.get(r, "raceEthnicity")) do
          true -> List.to_string(List.flatten(Map.get(r, "raceEthnicity")))
          false -> Map.get(r, "raceEthnicity")
        end

      %{
        :source => :namus,
        :id => Map.get(r, "idFormatted"),
        :first_name => capitalize(Map.get(r, "firstName")),
        :middle_name => capitalize(Map.get(r, "middle_name")),
        :last_name => capitalize(Map.get(r, "lastName")),
        :last_seen_date => Map.get(r, "dateOfLastContact"),
        :last_seen_min_age => Map.get(r, "computedMissingMinAge"),
        :last_seen_age => Map.get(r, "computedMissingMaxAge"),
        :last_seen_city => Map.get(r, "cityOfLastContact"),
        :last_seen_county => Map.get(r, "countyDisplayNameOfLastContact"),
        :last_seen_state => state,
        :nickname => Map.get(r, "nickname"),
        :race_ethnicity => ethnicity,
        :region => find_region_by_state(state),
        :gender => Map.get(r, "gender"),
        :details => Map.get(r, "text"),
        :last_updated => Map.get(r, "image"),
        :image => Map.get(r, "primary_photo"),
        :link => Map.get(r, "link"),
        :years_missing => Map.get(r, "missingAgeRangeValue"),
        :current_age_top => Map.get(r, "currentAgeFrom"),
        :current_age_bottom => Map.get(r, "currentAgeTo")
      }
    end)
  end

  def parse_lost(results) do
    data = Map.get(results, "results")

    Enum.map(data, fn r ->
      race_ethnicity = Map.get(r, "race") <> " / " <> Map.get(r, "ethnicity")

      %{
        "source" => :lostandfound,
        "id" => Map.get(r, "case_id"),
        "race_ethnicity" => race_ethnicity,
        "first_name" => capitalize(Map.get(r, "first_name")),
        "middle_name" => capitalize(Map.get(r, "middle_name")),
        "last_name" => capitalize(Map.get(r, "last_name")),
        "last_seen_date" => Map.get(r, "lka_date"),
        "last_seen_min_age" => Map.get(r, "min_age_lka"),
        "last_seen_max_age" => Map.get(r, "max_age_lka"),
        "last_seen_city" => nil,
        "last_seen_county" => nil,
        "last_seen_state" => Map.get(r, "state"),
        "nickname" => Map.get(r, "nickname"),
        "region" => Map.get(r, "region"),
        "gender" => Map.get(r, "sex"),
        "details" => Map.get(r, "text"),
        "last_updated" => Map.get(r, "date_created"),
        "image" => Map.get(r, "primary_photo"),
        "link" => nil,
        # TODO calculate this
        "years_missing" => nil,
        # TODO calculate this
        "current_age_top" => nil,
        # TODO calculate this
        "current_age_bottom" => nil,
        "height" => nil,
        "weight" => nil
      }
    end)
  end

  def parse_charley(results) do
    data = Map.get(results, "results")

    Enum.map(data, fn r ->
      race_ethnicity = Map.get(r, "race") <> " / " <> Map.get(r, "ethnicity")

      %{
        "source" => :lostandfound,
        "id" => Map.get(r, "case_id"),
        "race_ethnicity" => race_ethnicity,
        "first_name" => capitalize(Map.get(r, "first_name")),
        "middle_name" => capitalize(Map.get(r, "middle_name")),
        "last_name" => capitalize(Map.get(r, "last_name")),
        "last_seen_date" => Map.get(r, "lka_date"),
        "last_seen_min_age" => Map.get(r, "min_age_lka"),
        "last_seen_max_age" => Map.get(r, "max_age_lka"),
        "last_seen_city" => nil,
        "last_seen_county" => nil,
        "last_seen_state" => Map.get(r, "state"),
        "nickname" => Map.get(r, "nickname"),
        "region" => Map.get(r, "region"),
        "gender" => Map.get(r, "sex"),
        "details" => Map.get(r, "text"),
        "last_updated" => Map.get(r, "date_created"),
        "image" => Map.get(r, "primary_photo"),
        "link" => nil,
        # TODO calculate this
        "years_missing" => nil,
        # TODO calculate this
        "current_age_top" => nil,
        # TODO calculate this
        "current_age_bottom" => nil,
        "height" => nil,
        "weight" => nil
      }
    end)
  end

  def namus_data() do
    data =
      '{"predicates":[],"take":5000,"skip":0,"projections":["idFormatted","dateOfLastContact","lastName","firstName","computedMissingMinAge","computedMissingMaxAge","cityOfLastContact","countyDisplayNameOfLastContact","stateDisplayNameOfLastContact","gender","raceEthnicity","modifiedDateTime","namus2Number"],
      "orderSpecifications":[
        {"field":"dateOfLastContact","direction":"Descending"}
      ],
      "documentFragments":["birthDate"]
    }'

    {:ok, %{status_code: _, body: body}} = namus_request(data)
    Jason.decode!(~s(#{body}))
  end

  def lost_data() do
    {:ok, %{status_code: _, body: body}} = lost_request()
    Jason.decode!(~s(#{body}))
  end

  def charley_data() do
    # TODO add urls and header info to config?
    Hound.start_session(browser: "chrome")

    navigate_to(
      "http://charleyproject.org/case-searches/advanced-search?first-name=&middle-name=&last-name=&suffix=&missing-since=&missing-from-city=&missing-from-state=&classification=&date-of-birth=&age=&height-and-weight=&distinguishing-chars=&clothing-jewelry-desc=&medical-conditions=&details-of-disappearance=&investigating-agency=&source-information="
    )

    ps = page_source()

    urls =
      case ps do
        # TODO add logging 
        body when is_nil(body) ->
          []

        body ->
          body
          |> Floki.find("[class=case] a")
          |> Floki.attribute("href")
      end

    body =
      urls
      |> Enum.map(fn url ->
        navigate_to(url)
        ps_lvl_2 = page_source()
        full_name = inner_html(find_element(:class, "entry-title"))
        {first_name, middle_name, last_name} = divide_full_name(full_name)

        id =
          current_url()
          |> String.split("/")
          |> List.last()

        # missing_since = find_element(:xpath, ~s|//*[@id="case-top"]/div/div[2]/ul/li[1]|) 
        #   |> visible_text()
        #   |> String.replace("Missing Since\n", "")
        # missing_from = find_element(:xpath, ~s|//*[@id="case-top"]/div/div[2]/ul/li[2]|) 
        #   |> visible_text()
        #   |> String.replace("Missing From\n", "")

        # full_dob = find_element(:xpath, ~s|//*[@id="case-top"]/div/div[2]/ul/li[4]|) 
        #   |> visible_text()
        #   |> String.replace("Date of Birth\n", "")
        # [dob, parenthetical_age] = case String.contains?(full_dob, " ") do
        #   true -> String.split(full_dob, " ")
        #   false -> [full_dob, nil]
        # end
        # current_age = String.replace(parenthetical_age, "(", "") |> String.replace(")", "")
        # last_seen_age = find_element(:xpath, ~s|//*[@id="case-top"]/div/div[2]/ul/li[5]|) |> visible_text()
        #   |> String.replace(" years old", "")
        #   |> String.replace(" months old", "")
        # h_w = find_element(:xpath, ~s|//*[@id="case-top"]/div/div[2]/ul/li[6]|) |> visible_text()

        # chars = find_element(:xpath, ~s|//*[@id="case-top"]/div/div[2]/ul/li[8]|) |> visible_text()

        case_text =
          ps_lvl_2
          |> Floki.find("#case-top")
          |> Floki.text()

        clean_case = String.replace(case_text, "\t", "") |> String.replace("\n", "")

        [_, missing_since_full] =
          case String.contains?(clean_case, "Missing Since ") do
            true -> String.split(clean_case, "Missing Since ")
            false -> [nil, clean_case]
          end

        [missing_since, missing_from_full] =
          case String.contains?(missing_since_full, "Missing From ") do
            true -> String.split(missing_since_full, "Missing From ")
            false -> [nil, missing_since_full]
          end

        [missing_from, classification] =
          case String.contains?(missing_from_full, "Classification ") do
            true -> String.split(missing_from_full, "Classification ")
            false -> [nil, missing_from_full]
          end

        dob_full =
          case String.contains?(classification, "Date of Birth ") do
            true ->
              [_, dob_full] = String.split(classification, "Date of Birth ")
              dob_full

            false ->
              classification
          end

        [dob_date, age_full] =
          case String.contains?(dob_full, "Age ") do
            true -> String.split(dob_full, "Age ")
            false -> [nil, dob_full]
          end

        [age, hw_full] =
          case String.contains?(age_full, "Height and Weight ") do
            true -> String.split(age_full, "Height and Weight ")
            false -> [nil, age_full]
          end

        [hw, remaining] =
          case String.contains?(hw_full, "pounds") do
            true -> String.split(hw_full, "pounds")
            false -> [nil, hw_full]
          end

        [_, description] =
          case String.contains?(remaining, "Distinguishing Characteristics ") do
            true -> String.split(remaining, "Distinguishing Characteristics ")
            false -> [nil, nil]
          end

        last_seen_city =
          case String.contains?(missing_from, ",") do
            true ->
              [last_seen_city, _] = String.split(missing_from, ", ")
              last_seen_city

            false ->
              nil
          end

        last_seen_state =
          case String.contains?(missing_from, ",") do
            true ->
              [_, last_seen_state] = String.split(missing_from, ", ")
              last_seen_state

            false ->
              missing_from
          end

        [dob, parenthetical_age] =
          case dob_date do
            nil ->
              ["", ""]

            _ ->
              case String.contains?(dob_date, " ") do
                true -> String.split(dob_date, " ")
                false -> [dob_date, ""]
              end
          end

        current_age = String.replace(parenthetical_age, "(", "") |> String.replace(")", "")

        last_seen_age =
          age
          |> String.replace(" years old", "")
          |> String.replace(" months old", "")

        [height, weight] =
          case hw do
            nil -> ["", ""]
            _ -> String.split(hw, ", ")
          end

        [race, gender | _] =
          case description do
            nil -> ["", "", nil]
            _ -> String.split(description, " ")
          end

        details = find_element(:xpath, ~s|//*[@id="case-bottom"]/div/div[1]|) |> visible_text()

        IO.inspect(%{
          "source" => :charley,
          "id" => id,
          "race_ethnicity" => race,
          "first_name" => capitalize(first_name),
          "middle_name" => capitalize(middle_name),
          "last_name" => capitalize(last_name),
          "last_seen_date" => missing_since,
          "last_seen_min_age" => last_seen_age,
          "last_seen_max_age" => last_seen_age,
          "last_seen_city" => last_seen_city,
          "last_seen_county" => nil,
          "last_seen_state" => last_seen_state,
          "nickname" => nil,
          "region" => find_region_by_state(last_seen_state),
          "gender" => String.replace(gender, ".", ""),
          "details" => description <> " " <> details,
          "last_updated" => nil,
          "image" => nil,
          "link" => nil,
          # TODO calculate this
          "years_missing" => nil,
          "current_age_top" => current_age,
          "current_age_bottom" => current_age,
          "height" => height,
          "weight" => weight <> "lbs"
        })
      end)

    Hound.end_session()
    body
  end

  @doc """
  Makes the request to namus

  ## Parameters

  - data JSON
  """
  def namus_request(data) do
    url = "https://www.namus.gov/api/CaseSets/NamUs/MissingPersons/Search"

    HTTPoison.post(url, data, namus_headers(),
      ssl: [{:versions, [:"tlsv1.2"]}],
      recv_timeout: 5500
    )
  end

  def lost_request() do
    url =
      "https://lostandfound.revealnews.org/api/search/missing/?&ordering=Sort%20results%20by:&lka_date__gte=1900-01-01T00:00:00.000Z&lka_date__lte=&min_age_lka__gte=0&max_age_lka__lte=100&format=json"

    HTTPoison.get(url)
  end

  @doc """
  Create minimum headers to include with the request to NAMUS

  ## Return

  ```
  [
      {"Content-type", "application/PTI60"},
      {"MIME-Version", "1.1"},
      {"Request-number", "1"},
      {"Document-type", "Request"},
  ]
  ```
  """
  def namus_headers() do
    [
      {"Content-type", "application/json;charset=UTF-8"},
      {"Accept", "application/json, text/plain, */*"},
      {"Referer", "https://www.namus.gov/MissingPersons/Search"},
      {"Cookie",
       "www-namus-gov=daed0ddec8657a679f123ef30bf5e5c7; _ga=GA1.2.2011629222.1567287578; _gid=GA1.2.1086827328.1567287578; BIGipServerSCN_Prod_NGINIX=rd1o00000000000000000000ffff0a0f6004o443"}
    ]
  end

  # def doe_request() do
  #     Hound.start_session(browser: "chrome")

  #     navigate_to "http://www.doenetwork.org/mp-alpha-us.php"

  #     find_element(:xpath, ~s|//*[@id="visitor"]/div[1]/section/div/div/div[2]/aside/quick-search/div/div[1]/ul/li[1]|) |> click()
  #     find_element(:xpath, ~s|//*[@id="visitor"]/div[1]/section/div/div/div[2]/aside/quick-search/div/div[2]/form/fieldset/label[4]/div/ul/li/input|) |> click()
  #     find_element(:xpath, ~s|//*[@id="ui-select-choices-row-0-0"]|) |> click()
  #     selected_state = find_element(:xpath, ~s|//*[@id="visitor"]/div[1]/section/div/div/div[2]/aside/quick-search/div/div[2]/form/fieldset/label[4]/div/ul/span/li/span/span|)

  #     submit = find_element(:xpath, ~s|//*[@id="visitor"]/div[1]/section/div/div/div[2]/aside/quick-search/div/div[2]/form/div[2]/input[2]|)
  #     submit |> click()

  #     missing_results_check_url(current_url())

  #     html = find_element(:xpath, ~s|//*[@id="1567295304113-grid-container"]|) |> inner_html()

  #   end
  # end

  def missing_results_check_url(url, retry \\ 5) do
    case String.contains?(url, "results") do
      true ->
        # continue
        IO.inspect(current_url())

      false ->
        case retry >= 0 do
          true ->
            :timer.sleep(1000)
            missing_results_check_url(url, retry - 1)

          false ->
            IO.inspect("URL could not be advanced the results")
            IO.inspect(url)
        end
    end
  end

  def namus_by_hound() do
    # Hound.start_session(browser: "chrome")

    # navigate_to "https://www.namus.gov/Dashboard"
    # find_element(:xpath, ~s|//*[@id="visitor"]/div[1]/section/div/div/div[2]/aside/quick-search/div/div[1]/ul/li[1]|) |> click()
    # find_element(:xpath, ~s|//*[@id="visitor"]/div[1]/section/div/div/div[2]/aside/quick-search/div/div[2]/form/fieldset/label[4]/div/ul/li/input|) |> click()
    # find_element(:xpath, ~s|//*[@id="ui-select-choices-row-0-0"]|) |> click()
    # selected_state = find_element(:xpath, ~s|//*[@id="visitor"]/div[1]/section/div/div/div[2]/aside/quick-search/div/div[2]/form/fieldset/label[4]/div/ul/span/li/span/span|)

    # submit = find_element(:xpath, ~s|//*[@id="visitor"]/div[1]/section/div/div/div[2]/aside/quick-search/div/div[2]/form/div[2]/input[2]|)
    # submit |> click()

    # missing_results_check_url(current_url())

    # html = find_element(:xpath, ~s|//*[@id="1567295304113-grid-container"]|) |> inner_html()
  end

  def find_region_by_state(state) do
    case @regions do
      nil ->
        File.stream!("./lib/regions.csv")
        |> Enum.map(fn x -> String.split(x, ",") end)
        |> Enum.map(fn [_, s, r, _] -> {s, r} end)
        |> Enum.reduce(%{}, fn {state, region}, acc -> Map.put(acc, state, region) end)

      _ ->
        @regions
    end
    |> Map.get(state)
  end

  def capitalize(string) when is_nil(string), do: string
  def capitalize(string) when is_integer(string), do: string
  def capitalize(string), do: String.capitalize(string)

  def divide_full_name(full_name) when is_nil(full_name), do: full_name
  def divide_full_name(full_name) when is_integer(full_name), do: nil

  def divide_full_name(full_name) do
    {first_name, middle_name, last_name} = whats_in_a_name(String.split(full_name, " "))
  end

  def whats_in_a_name([first_name, middle_name | last_name]) do
    case is_list(last_name) do
      true -> {first_name, middle_name, concat_name(last_name, "")}
      false -> {first_name, middle_name, last_name}
    end
  end

  def whats_in_a_name([name]), do: {name, nil, nil}
  def whats_in_a_name(_), do: {nil, nil, nil}

  def concat_name([name | rest], acc), do: concat_name(rest, acc <> " " <> name)
  def concat_name([], acc), do: String.trim(acc)
end
