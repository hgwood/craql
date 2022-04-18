# I want only consultants to be able to see their timesheet

## A consultant can see their timesheet without specifying the consultant query param

GET http://localhost:8788/timesheets?month=2022-04
X-Sqlfe-User-Id: RDA
X-Sqlfe-Role: consultant
HTTP/* 200
[Asserts]
jsonpath "$.days['2022-04-01']" == "eat_cakes"
jsonpath "$.days['2022-04-02']" == "race"

## A consultant cannot see the timesheet of another consultant

POST http://localhost:8788/timesheets
{
  "date": "2022-05-01",
  "consultant": "TSP",
  "project": "eat_cakes"
}
HTTP/* 200

GET http://localhost:8788/timesheets?consultant=TSP&month=2022-05
X-Sqlfe-User-Id: RDA
X-Sqlfe-Role: consultant
HTTP/* 200
[Asserts]
jsonpath "$.days['2022-05-01']" not exists
