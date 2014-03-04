#!/bin/sh -u

diff sorted-counted-set.dk hashed-counted-set.dk
diff sorted-table.dk hashed-table.dk
diff sorted-counted-set.dk sorted-table.dk
diff hashed-counted-set.dk hashed-table.dk
