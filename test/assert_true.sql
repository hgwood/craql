create table if not exists assert_true (
  expectation boolean check (expectation)
);

create function assert_true(boolean) returns void volatile
  begin atomic
    insert into assert_true values ($1);
  end;
