# frozen_string_literal: true

# hello-flavor-acme — the reference EXTENSION slice's gem (spec 03 §2.8).
# A flavor registers itself on require; here that means defining the tag
# the base app appends to its greeting. The gem name IS the slice name:
# the base's drop-in requires the mount dir's basename, so the two must
# match (the feedstock owns both spellings — one name, two homes).
module HelloFlavor
  TAG = "acme flavor 0.1.0"
end
