defmodule WebWeb.CandidateController do
  use WebWeb, :controller

  def index(conn, %{"owner_screen_name" => owner_screen_name, "slug" => slug, "hints" => hints}) do
    list_member_ids =
      Twitter.Read.list_members(%{
        owner_screen_name: owner_screen_name,
        slug: slug
      })
      |> Enum.map(& &1.id)

    candidates =
      hints
      |> String.split(",")
      |> Twitter.friends_intersection()
      |> MapSet.difference(list_member_ids |> MapSet.new())
      |> Enum.to_list()
      |> Twitter.attach_profile()
      |> Enum.map(&Map.from_struct/1)

    list_members =
      list_member_ids
      |> Twitter.attach_profile()
      |> Enum.map(&Map.from_struct/1)

    json(conn, %{"candidates" => candidates, "list_members" => list_members})
  end

  def add_to_list(conn, %{
        "owner_screen_name" => owner_screen_name,
        "slug" => slug,
        "user_ids" => user_ids
      }) do
    user_ids = user_ids |> Enum.map(&coerce_integer/1)
    Twitter.Write.add_to_list(owner_screen_name, slug, user_ids)

    json(conn, %{"msg" => "success"})
  end

  def user(conn, %{"user_screen_name_or_id" => identifier}) do
    user = Twitter.Read.user(%{id_or_screen_name: identifier})

    conn |> json(Map.from_struct(user))
  end

  def remove_from_list(conn, %{
        "owner_screen_name" => owner_screen_name,
        "slug" => slug,
        "user_ids" => user_ids
      }) do
    user_ids = user_ids |> Enum.map(&coerce_integer/1)
    Twitter.Write.remove_from_list(owner_screen_name, slug, user_ids)

    json(conn, %{"msg" => "success"})
  end

  defp coerce_integer(s) do
    if is_binary(s) do
      String.to_integer(s)
    else
      s
    end
  end
end
