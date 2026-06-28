# Rules

## Naming Rules

- API JSON fields use camelCase: `itemId`, `itemName`.
- Go struct fields use PascalCase with uppercase acronyms: `ItemID`, `UserID`.
- Database columns use snake_case: `item_id`, `user_id`.
- Go JSON tags must match API field names: `json:"itemId"`.
- GORM column tags must match DB columns: `gorm:"column:item_id"`.
- Error code constants: `Err` + PascalCase, e.g. `ErrNotFound`.
- URL paths: kebab-case with resource nouns, e.g. `/api/v1/items`.
