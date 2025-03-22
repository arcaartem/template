#!/usr/bin/env bats

setup() {
    # Get the absolute path to the project root directory
    PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
    SCRIPT_DIR="$PROJECT_ROOT/test"
    TEMPLATE_SCRIPT="$PROJECT_ROOT/src/template.sh"
    FIXTURES_DIR="$SCRIPT_DIR/fixtures"
}

@test "basic substitution" {
    output="$("$TEMPLATE_SCRIPT" "$FIXTURES_DIR/basic.txt" "NAME=World")"
    [ $? -eq 0 ]
    [[ "$output" == *"Hello, World!"* ]]
    [[ "$output" == *"$(date +%Y)"* ]]
}

@test "include directive" {
    output="$("$TEMPLATE_SCRIPT" "$FIXTURES_DIR/include_test.txt" "CONTENT=Test")"
    [ $? -eq 0 ]
    [[ "$output" == *"=== Header ==="* ]]
    [[ "$output" == *"Content: Test"* ]]
}

@test "conditional if true" {
    output="$("$TEMPLATE_SCRIPT" "$FIXTURES_DIR/conditional.txt" "NAME=World" "SHOW_GREETING=true")"
    [ $? -eq 0 ]
    [[ "$output" == *"Hello, World!"* ]]
}

@test "conditional if false" {
    output="$("$TEMPLATE_SCRIPT" "$FIXTURES_DIR/conditional.txt" "NAME=World" "SHOW_GREETING=false")"
    [ $? -eq 0 ]
    [[ "$output" == *"Goodbye, World!"* ]]
}

@test "error handling for missing template" {
    run bash -c '"$1" "$2" 2>&1' -- "$TEMPLATE_SCRIPT" "nonexistent.txt"
    [ $status -eq 1 ]
    [[ "$output" == *"Error: Template file not found"* ]]
}

@test "nested conditionals - all true" {
    output="$("$TEMPLATE_SCRIPT" "$FIXTURES_DIR/nested_conditional.txt" "OUTER=true" "INNER=true")"
    [ $? -eq 0 ]
    [[ "$output" == *"Start"* ]]
    [[ "$output" == *"Outer true"* ]]
    [[ "$output" == *"Inner true"* ]]
    [[ "$output" == *"End"* ]]
}

@test "nested conditionals - outer true, inner false" {
    output="$("$TEMPLATE_SCRIPT" "$FIXTURES_DIR/nested_conditional.txt" "OUTER=true" "INNER=false")"
    [ $? -eq 0 ]
    [[ "$output" == *"Outer true"* ]]
    [[ "$output" == *"Inner false"* ]]
}

@test "nested conditionals - outer false" {
    output="$("$TEMPLATE_SCRIPT" "$FIXTURES_DIR/nested_conditional.txt" "OUTER=false" "INNER=true")"
    [ $? -eq 0 ]
    [[ "$output" == *"Outer false"* ]]
    [[ "$output" != *"Inner"* ]]
}

@test "complex conditional - active admin user" {
    output="$("$TEMPLATE_SCRIPT" "$FIXTURES_DIR/complex_conditional.txt" \
        "STATUS=active" "NAME=John" "ADMIN=true")"
    [ $? -eq 0 ]
    [[ "$output" == *"User John is active"* ]]
    [[ "$output" == *"has admin privileges"* ]]
}

@test "complex conditional - active regular user" {
    output="$("$TEMPLATE_SCRIPT" "$FIXTURES_DIR/complex_conditional.txt" \
        "STATUS=active" "NAME=Jane" "ADMIN=false")"
    [ $? -eq 0 ]
    [[ "$output" == *"User Jane is active"* ]]
    [[ "$output" == *"But is a regular user"* ]]
}

@test "nested include with variables" {
    output="$("$TEMPLATE_SCRIPT" "$FIXTURES_DIR/welcome_email.txt" \
        "NAME=Alice" \
        "EMAIL=alice@example.com" \
        "ROLE=Developer" \
        "STATUS=Active")"
    [ $? -eq 0 ]
    [[ "$output" == *"Welcome to our platform!"* ]]
    [[ "$output" == *"Status: Active"* ]]
    [[ "$output" == *"Name: Alice"* ]]
    [[ "$output" == *"Email: alice@example.com"* ]]
    [[ "$output" == *"Role: Developer"* ]]
}

@test "deep nested conditionals - all true" {
    output="$("$TEMPLATE_SCRIPT" "$FIXTURES_DIR/deep_nested_conditional.txt" \
        "LEVEL1=true" "LEVEL2=true" "LEVEL3=true")"
    [ $? -eq 0 ]
    [[ "$output" == *"Level 1 true"* ]]
    [[ "$output" == *"Level 2 true"* ]]
    [[ "$output" == *"Level 3 true"* ]]
}

@test "deep nested conditionals - first two true, last false" {
    output="$("$TEMPLATE_SCRIPT" "$FIXTURES_DIR/deep_nested_conditional.txt" \
        "LEVEL1=true" "LEVEL2=true" "LEVEL3=false")"
    [ $? -eq 0 ]
    [[ "$output" == *"Level 1 true"* ]]
    [[ "$output" == *"Level 2 true"* ]]
    [[ "$output" == *"Level 3 false"* ]]
}

@test "deep nested conditionals - first true, second false, third true" {
    output="$("$TEMPLATE_SCRIPT" "$FIXTURES_DIR/deep_nested_conditional.txt" \
        "LEVEL1=true" "LEVEL2=false" "LEVEL3=true")"
    [ $? -eq 0 ]
    [[ "$output" == *"Level 1 true"* ]]
    [[ "$output" == *"Level 2 false"* ]]
    [[ "$output" == *"Level 2 false, Level 3 true"* ]]
}

@test "deep nested conditionals - first false" {
    output="$("$TEMPLATE_SCRIPT" "$FIXTURES_DIR/deep_nested_conditional.txt" \
        "LEVEL1=false" "LEVEL2=true" "LEVEL3=true")"
    [ $? -eq 0 ]
    [[ "$output" == *"Level 1 false"* ]]
    [[ "$output" != *"Level 2"* ]]
    [[ "$output" != *"Level 3"* ]]
}

@test "complex nested conditionals - all true" {
    output="$("$TEMPLATE_SCRIPT" "$FIXTURES_DIR/complex_nested.txt" \
        "A=true" "B=true" "C=true")"
    [ $? -eq 0 ]
    [[ "$output" == *"Start"* ]]
    [[ "$output" == *"A is true"* ]]
    [[ "$output" == *"A and B are true"* ]]
    [[ "$output" == *"A, B, and C are true"* ]]
    [[ "$output" == *"End"* ]]
}

@test "complex nested conditionals - A and B true, C false" {
    output="$("$TEMPLATE_SCRIPT" "$FIXTURES_DIR/complex_nested.txt" \
        "A=true" "B=true" "C=false")"
    [ $? -eq 0 ]
    [[ "$output" == *"A is true"* ]]
    [[ "$output" == *"A and B are true"* ]]
    [[ "$output" == *"A and B are true, but C is false"* ]]
}

@test "complex nested conditionals - A true, B false, C true" {
    output="$("$TEMPLATE_SCRIPT" "$FIXTURES_DIR/complex_nested.txt" \
        "A=true" "B=false" "C=true")"
    [ $? -eq 0 ]
    [[ "$output" == *"A is true"* ]]
    [[ "$output" == *"A is true but B is false"* ]]
    [[ "$output" == *"A is true, B is false, C is true"* ]]
}

@test "complex nested conditionals - A false" {
    output="$("$TEMPLATE_SCRIPT" "$FIXTURES_DIR/complex_nested.txt" \
        "A=false" "B=true" "C=true")"
    [ $? -eq 0 ]
    [[ "$output" == *"A is false"* ]]
    [[ "$output" == *"A is false but B is true"* ]]
    [[ "$output" == *"A is false, but B and C are true"* ]]
} 
