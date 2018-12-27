defmodule WebWeb.Router do
  use WebWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WebWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/api", WebWeb do
    pipe_through :api

    resources "/candidates", CandidateController
    get "/user", CandidateController, :user
    post "/list_members", CandidateController, :add_to_list
    delete "/list_members", CandidateController, :remove_from_list
  end
end
