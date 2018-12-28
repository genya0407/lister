defmodule Twitter.Cache do
  def query_or_exec(func_name, params, proc) do
    case query(func_name, params) do
      {:ok, nil} ->
        result = proc.()
        store(func_name, params, result)
        result

      {:ok, result} ->
        result
    end
  end

  def query(func_name, params) do
    Cachex.get(:twitter_cache, %{func_name: func_name, params: params})
  end

  def store(func_name, params, result) do
    Cachex.execute!(:twitter_cache, fn cache ->
      Cachex.put(cache, %{func_name: func_name, params: params}, result)
    end)
  end

  def store_bulk(func_name, values) do
    pairs =
      values
      |> Enum.map(fn {params, result} -> {%{func_name: func_name, params: params}, result} end)

    Cachex.put_many(:twitter_cache, pairs)
  end
end

defmodule Twitter.Read do
  def list_members(params = %{slug: slug, owner_screen_name: owner_screen_name}) do
    Twitter.Cache.query_or_exec(:list_members, params, fn ->
      ExTwitter.list_members(slug, owner_screen_name, count: 5000)
    end)
  end

  def user(params = %{id_or_screen_name: value}) do
    Twitter.Cache.query_or_exec(:user, params, fn ->
      ExTwitter.user(value)
    end)
  end

  def users(user_identifiers) do
    user_identifiers
    |> Enum.filter(fn user_identifier ->
      case Twitter.Cache.query(:user, %{id_or_screen_name: user_identifier}) do
        {:ok, nil} -> true
        {:ok, _} -> false
      end
    end)
    |> Enum.chunk_every(100)
    |> Enum.map(fn chunked_user_identifiers ->
      ExTwitter.user_lookup(chunked_user_identifiers)
      |> Enum.map(fn user ->
        [
          {%{id_or_screen_name: user.id}, user},
          {%{id_or_screen_name: user.screen_name}, user}
        ]
      end)
      |> Enum.concat()
    end)
    |> Enum.concat()
    |> IO.inspect()
    |> (&Twitter.Cache.store_bulk(:user, &1)).()

    result =
      user_identifiers
      |> Enum.map(fn user_identifier ->
        Twitter.Read.user(%{id_or_screen_name: user_identifier})
      end)

    result
  end

  def friend_ids(params = %{id: user_id}) do
    Twitter.Cache.query_or_exec(:friend_ids, params, fn ->
      ExTwitter.friend_ids(user_id).items
    end)
  end
end

defmodule Twitter.Write do
  def add_to_list(owner_screen_name, slug, user_ids) do
    user_id = user_ids |> Enum.join(",")
    owner = Twitter.Read.user(%{id_or_screen_name: owner_screen_name})

    params =
      ExTwitter.Parser.parse_request_params(
        owner_id: owner.id,
        slug: slug,
        user_id: user_id
      )

    ExTwitter.request(:post, "1.1/lists/members/create_all.json", params)

    members =
      Twitter.Read.list_members(%{owner_screen_name: owner.screen_name, slug: slug}) ++
        Twitter.Read.users(user_ids)

    Twitter.Cache.store(
      :list_members,
      %{slug: slug, owner_screen_name: owner.screen_name},
      members
    )
  end

  def remove_from_list(owner_screen_name, slug, user_ids) do
    user_id = user_ids |> Enum.join(",")
    owner = Twitter.Read.user(%{id_or_screen_name: owner_screen_name})

    params =
      ExTwitter.Parser.parse_request_params(
        owner_id: owner.id,
        slug: slug,
        user_id: user_id
      )

    ExTwitter.request(:post, "1.1/lists/members/destroy_all.json", params)

    members =
      Twitter.Read.list_members(%{owner_screen_name: owner.screen_name, slug: slug})
      |> Enum.reject(fn user -> Enum.member?(user_ids, user.id) end)

    Twitter.Cache.store(
      :list_members,
      %{slug: slug, owner_screen_name: owner.screen_name},
      members
    )
  end
end

defmodule Twitter do
  def friends_intersection(user_identifiers) do
    user_identifiers
    |> Twitter.Read.users()
    |> Enum.map(fn u ->
      Twitter.Read.friend_ids(%{id: u.id}) |> MapSet.new()
    end)
    |> Enum.reduce(fn m1, m2 -> MapSet.intersection(m1, m2) end)
  end
end
