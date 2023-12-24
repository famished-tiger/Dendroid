# frozen_string_literal: true

# File: dendroid.rb

# Namespace for all modules, classes and constants from Dendroid library.
module Dendroid
end # module

# This file acts as a jumping-off point for loading dependencies expected
# for a Dendroid client.
require_relative './dendroid/grm_dsl/base_grm_builder'
require_relative './dendroid/utils/base_tokenizer'
require_relative './dendroid/recognizer/recognizer'
require_relative './dendroid/parsing/chart_walker'
require_relative './dendroid/parsing/parse_tree_visitor'
require_relative './dendroid//formatters/ascii_tree'
