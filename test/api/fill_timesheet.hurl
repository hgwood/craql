# I want to set the project for a consultant and a day, aka change the timesheet

## Changes are persisted

POST http://localhost:8788/timesheets
{
  "date": "2022-05-01",
  "consultant": "RDA",
  "project": "friendship_magic"
}
HTTP/* 200

GET http://localhost:8788/timesheets?consultant=RDA&month=2022-05
HTTP/* 200
[Asserts]
jsonpath "$['2022-05-01']" != "eat_cakes"

POST http://localhost:8788/timesheets
{
  "date": "2022-05-01",
  "consultant": "RDA",
  "project": "eat_cakes"
}
HTTP/* 200

GET http://localhost:8788/timesheets?consultant=RDA&month=2022-05
HTTP/* 200
[Asserts]
jsonpath "$['2022-05-01']" == "eat_cakes"
