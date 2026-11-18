# The 15 open baseline tasks

The IDs and input domains below identify the original open tasks. The complete fixtures contain the inputs and expected outputs used for measurement. [Frozen public fixtures](aufgaben.json)

| ID | Task |
|---|---|
| W01 | Compute an order line's value in cents as quantity times unit price. Both inputs are nonnegative integers up to one million. |
| W02 | Return the smaller of the requested and available quantities. Both are nonnegative. |
| W03 | Count the UTF-8 bytes in the original shipping label, including empty strings and combining characters. |
| W04 | Read integer `qty` from a valid JSON object. Ignore unknown fields. Keys are unique and the quantity ranges from zero through one million. |
| W05 | Store receipt IDs in a fresh SQLite database with bound parameters and a unique `receipt(id TEXT PRIMARY KEY)` column. Return the number of distinct stored IDs. |
| E01 | Approve the discount at or above the minimum amount. Return 1 when approved and 0 otherwise. The previous policy required an amount strictly above the minimum. |
| E02 | Change shipping-label billing from character count to UTF-8 byte count. ASCII labels keep their existing result. |
| E03 | Compute ordered minus delivered, with a floor of zero for excess deliveries. |
| E04 | Sum only positive inventory movements. The old total also included negative adjustments. |
| E05 | Change the shipping tariff to the base price plus one fixed fee. The old tariff charged the fee per unit. All three inputs are nonnegative. |
| R01 | Repair the signed receiving balance, delivered minus ordered, in both the entry point and the intermediate function. |
| R02 | Repair the shipping check value, booked units minus cancelled units plus the label's UTF-8 byte count. Check the intermediate function directly. |
| R03 | Repair the invoice total, net amount plus a one-time fee, both in cents. |
| R04 | Return the number of loose parts after filling complete cartons. Quantity is nonnegative and carton capacity is strictly positive. |
| R05 | Return 1 for the ASCII status code `OK` regardless of case, and 0 for all other codes. |

W tasks start from an empty source directory. E tasks extend an existing project. R tasks repair a fault. The separate 15-task final evaluation remains sealed. [Baseline report](report.md)
