# I want to see the number of days allocated to each project within a month

## It returns 200

GET http://localhost:8788/projects?month=2022-04
HTTP/* 200

## It returns JSON

GET http://localhost:8788/projects?month=2022-04
HTTP/* 200
[Asserts]
header "Content-Type" == "application/json"

## It requires month query param

GET http://localhost:8788/projects
HTTP/* 400
