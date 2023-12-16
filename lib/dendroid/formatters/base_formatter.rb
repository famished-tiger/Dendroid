# frozen_string_literal: true


# Superclass for parse tree formatters.
class BaseFormatter
  # The IO output stream in which the formatter's result will be sent.
  # @return [IO] The output stream for the formatter.
  attr_reader(:output)

  # Constructor.
  # @param anIO [IO] an output IO where the formatter's result will
  # be placed.
  def initialize(anIO)
    @output = anIO
  end

  # Given a parse tree visitor, perform the visit
  # and render the visit events in the output stream.
  # @param aVisitor [ParseTreeVisitor]
  def render(aVisitor)
    aVisitor.subscribe(self)
    aVisitor.start
    aVisitor.unsubscribe(self)
  end
end # class
