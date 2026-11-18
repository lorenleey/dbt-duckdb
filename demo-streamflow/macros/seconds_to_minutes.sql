{% macro seconds_to_minutes(expression) %}
    round(({{ expression }}) / 60.0, 2)
{% endmacro %}
