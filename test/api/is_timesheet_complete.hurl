# I want to see if each day of a month has a project set for a consultant, aka if their timesheet is complete for a month

POST http://localhost:8788/timesheets
{
  "month": "2022-08",
  "consultant": "RDA",
  "project": "eat_cakes"
}
HTTP/* 200

GET http://localhost:8788/timesheets?consultant=RDA&month=2022-08
HTTP/* 200
[Asserts]
jsonpath "$.complete" == true
