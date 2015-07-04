// -*- mode: Dakota; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

enum rate_t : int;

enum rate { slow, average, fast };

enum rate_t : int;

// can not forward declare this
enum : int { little, big };

int main() { return 0; }
