# I want to set a project for a consultant for a whole month

## Changes are persisted

POST http://localhost:8788/timesheets
{
  "date": "2022-04-30",
  "consultant": "RDA",
  "project": "friendship_magic"
}
HTTP/* 200

POST http://localhost:8788/timesheets
{
  "month": "2022-05",
  "consultant": "RDA",
  "project": "friendship_magic"
}
HTTP/* 200

POST http://localhost:8788/timesheets
{
  "date": "2022-06-01",
  "consultant": "RDA",
  "project": "friendship_magic"
}
HTTP/* 200

GET http://localhost:8788/timesheets?consultant=RDA&month=2022-05
HTTP/* 200
[Asserts]
jsonpath "$['2022-05-01']" != "eat_cakes"
jsonpath "$['2022-05-02']" != "eat_cakes"
jsonpath "$['2022-05-03']" != "eat_cakes"
jsonpath "$['2022-05-04']" != "eat_cakes"
jsonpath "$['2022-05-05']" != "eat_cakes"
jsonpath "$['2022-05-06']" != "eat_cakes"
jsonpath "$['2022-05-07']" != "eat_cakes"
jsonpath "$['2022-05-08']" != "eat_cakes"
jsonpath "$['2022-05-09']" != "eat_cakes"
jsonpath "$['2022-05-10']" != "eat_cakes"
jsonpath "$['2022-05-11']" != "eat_cakes"
jsonpath "$['2022-05-12']" != "eat_cakes"
jsonpath "$['2022-05-13']" != "eat_cakes"
jsonpath "$['2022-05-14']" != "eat_cakes"
jsonpath "$['2022-05-15']" != "eat_cakes"
jsonpath "$['2022-05-16']" != "eat_cakes"
jsonpath "$['2022-05-17']" != "eat_cakes"
jsonpath "$['2022-05-18']" != "eat_cakes"
jsonpath "$['2022-05-19']" != "eat_cakes"
jsonpath "$['2022-05-20']" != "eat_cakes"
jsonpath "$['2022-05-21']" != "eat_cakes"
jsonpath "$['2022-05-22']" != "eat_cakes"
jsonpath "$['2022-05-23']" != "eat_cakes"
jsonpath "$['2022-05-24']" != "eat_cakes"
jsonpath "$['2022-05-25']" != "eat_cakes"
jsonpath "$['2022-05-26']" != "eat_cakes"
jsonpath "$['2022-05-27']" != "eat_cakes"
jsonpath "$['2022-05-28']" != "eat_cakes"
jsonpath "$['2022-05-29']" != "eat_cakes"
jsonpath "$['2022-05-30']" != "eat_cakes"
jsonpath "$['2022-05-31']" != "eat_cakes"

GET http://localhost:8788/timesheets?consultant=RDA&month=2022-04
HTTP/* 200
[Asserts]
jsonpath "$['2022-04-30']" != "eat_cakes"

GET http://localhost:8788/timesheets?consultant=RDA&month=2022-06
HTTP/* 200
[Asserts]
jsonpath "$['2022-06-01']" != "eat_cakes"

POST http://localhost:8788/timesheets
{
  "month": "2022-05",
  "consultant": "RDA",
  "project": "eat_cakes"
}
HTTP/* 200

GET http://localhost:8788/timesheets?consultant=RDA&month=2022-05
HTTP/* 200
[Asserts]
jsonpath "$['2022-05-01']" == "eat_cakes"
jsonpath "$['2022-05-02']" == "eat_cakes"
jsonpath "$['2022-05-03']" == "eat_cakes"
jsonpath "$['2022-05-04']" == "eat_cakes"
jsonpath "$['2022-05-05']" == "eat_cakes"
jsonpath "$['2022-05-06']" == "eat_cakes"
jsonpath "$['2022-05-07']" == "eat_cakes"
jsonpath "$['2022-05-08']" == "eat_cakes"
jsonpath "$['2022-05-09']" == "eat_cakes"
jsonpath "$['2022-05-10']" == "eat_cakes"
jsonpath "$['2022-05-11']" == "eat_cakes"
jsonpath "$['2022-05-12']" == "eat_cakes"
jsonpath "$['2022-05-13']" == "eat_cakes"
jsonpath "$['2022-05-14']" == "eat_cakes"
jsonpath "$['2022-05-15']" == "eat_cakes"
jsonpath "$['2022-05-16']" == "eat_cakes"
jsonpath "$['2022-05-17']" == "eat_cakes"
jsonpath "$['2022-05-18']" == "eat_cakes"
jsonpath "$['2022-05-19']" == "eat_cakes"
jsonpath "$['2022-05-20']" == "eat_cakes"
jsonpath "$['2022-05-21']" == "eat_cakes"
jsonpath "$['2022-05-22']" == "eat_cakes"
jsonpath "$['2022-05-23']" == "eat_cakes"
jsonpath "$['2022-05-24']" == "eat_cakes"
jsonpath "$['2022-05-25']" == "eat_cakes"
jsonpath "$['2022-05-26']" == "eat_cakes"
jsonpath "$['2022-05-27']" == "eat_cakes"
jsonpath "$['2022-05-28']" == "eat_cakes"
jsonpath "$['2022-05-29']" == "eat_cakes"
jsonpath "$['2022-05-30']" == "eat_cakes"
jsonpath "$['2022-05-31']" == "eat_cakes"

GET http://localhost:8788/timesheets?consultant=RDA&month=2022-04
HTTP/* 200
[Asserts]
jsonpath "$['2022-04-30']" != "eat_cakes"

GET http://localhost:8788/timesheets?consultant=RDA&month=2022-06
HTTP/* 200
[Asserts]
jsonpath "$['2022-06-01']" != "eat_cakes"
