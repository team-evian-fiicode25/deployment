resource "aws_budgets_budget" "budget" {
  name              = "monthly-budget"
  budget_type       = "COST"
  limit_amount      = "30.0"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-03-15_00:01"
}
