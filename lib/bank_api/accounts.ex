defmodule BankAPI.Accounts do
  import Ecto.Query, warn: false

  alias BankAPI.Repo
  alias BankAPI.Router

  alias BankAPI.Accounts.Commands.{
    OpenAccount,
    CloseAccount,
    DepositIntoAccount,
    WithdrawFromAccount
  }

  alias BankAPI.Accounts.Projections.Account

  def deposit(id, amount) do
    dispatch_result =
      %DepositIntoAccount{
        account_uuid: id,
        deposit_amount: amount
      }
      |> Router.dispatch(consistency: :strong)

    IO.inspect(dispatch_result)

    case dispatch_result do
      :ok ->
        {:ok, _} = get_account(id)

      reply ->
        reply
    end
  end

  def withdraw(id, amount) do
    dispatch_result =
      %WithdrawFromAccount{
        account_uuid: id,
        withdraw_amount: amount
      }
      |> Router.dispatch()

    case dispatch_result do
      :ok ->
        {:ok, _} = get_account(id)

      reply ->
        reply
    end
  end

  def get_account(uuid) do
    case Repo.get(Account, uuid) do
      %Account{} = account ->
        {:ok, account}

      _reply ->
        {:error, :not_found}
    end
  end

  def close_account(id) do
    %CloseAccount{
      account_uuid: id
    }
    |> Router.dispatch()
  end

  def open_account(%{"initial_balance" => initial_balance}) do
    account_uuid = UUID.uuid4()

    dispatch_result =
      %OpenAccount{
        initial_balance: initial_balance,
        account_uuid: account_uuid
      }
      |> Router.dispatch()

    case dispatch_result do
      :ok ->
        {:ok,
         %Account{
           uuid: account_uuid,
           current_balance: initial_balance
         }}

      reply ->
        reply
    end
  end

  def open_account(_params), do: {:error, :bad_command}

  def uuid_regex do
    ~r/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
  end
end
