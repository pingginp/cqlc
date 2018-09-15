CCM_NODE ?= node1
CQLSH_CMD ?= ccm $(CCM_NODE) cqlsh

.PHONY: build
build:
	go build -o build/cqlc .

.PHONY: install
install:
	go install .

test/collections.cql: test/tmpl/schema.tmpl test/schema_generator.go
	cd test; go run schema_generator.go

test/.fixtures/collections/input.go: test/tmpl/input.tmpl test/schema_generator.go
	cd test; go run schema_generator.go

schema: test/collections.cql
	-$(CQLSH_CMD) -f test/keyspace.cql
	$(CQLSH_CMD) -k cqlc -f test/schema.cql
	$(CQLSH_CMD) -k cqlc -f test/collections.cql
	$(CQLSH_CMD) -k cqlc -f test/shared.cql
	$(CQLSH_CMD) -k cqlc2 -f test/shared.cql

cqlc/columns.go: cqlc/tmpl/columns.tmpl cqlc/column_generator.go
	cd cqlc; go run column_generator.go

columns: cqlc/columns.go

input: test/.fixtures/collections/input.go test/collections.cql

# FIXME: generator won't work due to go vendor ... inspect type does not equal
#test: columns schema test/.fixtures/collections/input.go
#	go test -v ./cqlc
test: test-unit

test-unit:
	go test -v ./cqlc

format:
	gofmt -w cqlc generator integration test

travis-test:
	docker-compose -f e2e/docker-compose.yaml up -d c2
	./wait-on-c.sh
	docker ps
	sleep 5
	go test -v ./e2e

travis-tear:
	cd e2e && make down

.PHONY: test columns