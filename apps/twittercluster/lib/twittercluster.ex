defmodule Twittercluster.ListUpdate do
  def add_to_list(owner_id, slug, user_ids) do
    user_id = user_ids |> Enum.join(",")

    params =
      ExTwitter.Parser.parse_request_params(
        owner_id: owner_id,
        slug: slug,
        user_id: user_id
      )

    ExTwitter.request(:post, "1.1/lists/members/create_all.json", params)
  end
end

defmodule Twittercluster.FetchCandidates do
  def friends_intersection(users) do
    users
    |> Enum.map(fn u -> ExTwitter.user(u).id end)
    |> Enum.map(fn u -> friends(u) |> MapSet.new() end)
    |> Enum.reduce(fn m1, m2 -> MapSet.intersection(m1, m2) end)
    |> MapSet.to_list()
  end

  def attach_profile(user_ids) do
    user_ids
    |> Flow.from_enumerable()
    |> Flow.map(fn id -> ExTwitter.user(id) end)
    |> Enum.to_list()
  end

  def friends(user_id) do
    fname = "priv/friends/#{user_id}.json"

    if File.exists?(fname) do
      File.read!(fname) |> Poison.decode!() |> Map.get("ids")
    else
      friend_ids = ExTwitter.friend_ids(user_id).items
      File.write!(fname, Poison.encode!(%{:ids => friend_ids}))
      friend_ids
    end
  end
end
