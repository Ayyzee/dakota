# include <cstdio>
# include <cstdlib>

int main() {
  return 0;
}
[[dk::initializer]] static void my_initializer() {
  printf("%s\n", __func__);
}
[[dk::finalizer]] static void my_finalizer() {
  printf("%s\n", __func__);
}
