# Power BI Dashboard Build Guide

## Data model
1. Get Data > Text/CSV > `data/superstore_clean.csv`.
2. Set Order Date and Ship Date to Date; Sales, Profit to Decimal Number; Quantity to Whole Number; Discount to Decimal Number.
3. Create the Date table using the DAX in `DAX_measures.txt`.
4. Mark Date as the date table and relate Date[Date] to Superstore[Order Date].
5. Create all listed measures. Use measures rather than implicit sums where possible.

## Page 1 — Executive Overview
- KPI cards: Total Sales, Total Profit, Profit Margin, Total Orders, Total Customers, Average Order Value.
- Line chart: monthly Sales and Profit.
- Bar chart: Sales by Category.
- Bar chart: Profit by Region.
- Slicers: Year, Region, Segment.

## Page 2 — Product Performance
- Matrix: Category > Sub-Category with Sales, Profit, Profit Margin, Quantity.
- Bar chart: Top 10 products by Profit.
- Bar chart: Bottom 10 products by Profit.
- Scatter chart: Product Sales (X) vs Product Profit (Y); detail Product Name.
- Slicers: Category, Sub-Category.

## Page 3 — Customer Analytics
- KPI cards: Customers, Orders, Average Order Value.
- Bar chart: Sales and Profit by Segment.
- Table: Customer Name, Sales, Profit, Orders, AOV, Profit Margin.
- Scatter chart: Customer Sales vs Customer Profit; detail Customer Name.
- Filter/table to inspect customers with negative aggregate profit.

## Page 4 — Geographic Performance
- Filled map or Azure Maps: State by Profit (use State and Country to disambiguate).
- Bar chart: Profit by State (top/bottom 10).
- Bar chart: Sales and Profit by Region.
- Matrix: Region > State with Sales, Profit, Profit Margin.
- Slicers: Region, State.

## Page 5 — Discount & Operations
- Create a Discount Band calculated column using the same band definitions as the Python notebook.
- Column chart: Profit Margin by Discount Band.
- Matrix: Category x Discount Band with Sales, Profit, Profit Margin.
- Bar chart: Average Shipping Days by Ship Mode.
- KPI: Loss-Making Lines.
- Table: negative-profit transactions with Order ID, Product, Sales, Discount, Profit.

## Design recommendations
- Keep a consistent 2–3 color palette and align KPI cards.
- Use titles that state the question answered, e.g. "Which sub-categories erode profit?"
- Add report-page tooltips where helpful.
- Avoid putting too many visuals on one page; prioritize readable labels and useful slicers.
- Add a footer with data period and last refresh date.

## Important interpretation notes
- A row is an order line, not necessarily a unique order.
- Use DISTINCTCOUNT(Order ID) for orders and DISTINCTCOUNT(Customer ID) for customers.
- Profit Margin must be calculated as total profit / total sales, not an average of row-level margins.
- Discount-profit patterns are descriptive associations, not proof of causation.
- A Power BI `.pbix` file must be assembled and saved in Power BI Desktop; this package provides the data, measures, model setup and page blueprint.
