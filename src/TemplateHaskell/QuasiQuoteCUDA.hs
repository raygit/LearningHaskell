
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}

-- The example now is to emit GPU kernels that will eventually be compiled and
-- run against GPGPUs.
--

import qualified Language.C.Quote.CUDA as Cuda
import qualified Language.C.Syntax as C
import Text.PrettyPrint.Mainland
import Text.PrettyPrint.Mainland.Class (Pretty (..))

cuda_fun :: String -> Int -> Float -> C.Func
cuda_fun fn n a =
  [Cuda.cfun|
  
  __global__ void $id:fn (float *x, float *y) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if ( i < $n ) { y[i] = $a * x[i] + y[i]  ; }
  }

  |]

cuda_driver :: String -> Int -> C.Func
cuda_driver fn n =
  [Cuda.cfun|
 
   void driver(float * x, float *y) {
   float *d_x, *d_y;

   cudaMalloc(&d_x, $n*sizeof(float));
   cudaMalloc(&d_y, $n*sizeof(float));

   cudaMemcpy(d_x, x, $n, cudaMemcpyHostToDevice);
   cudaMemcpy(d_y, y, $n, cudaMemcpyHostToDevice);

   $id:fn<<<($n+255)/256, 256>>>(d_x, d_y);

   cudaFree(d_x);
   cudaFree(d_y);
   
   return 0;
   }
  |]


makeKernel :: String -> Float -> Int -> [C.Func]
makeKernel fn a n = [cuda_fun fn n a, cuda_driver fn n]

{-
 -  Example of a run
 -  *Main> main
 -  __global__ void saxpy(float *x, float *y)
 -  {
 -      int i = blockIdx.x * blockDim.x + threadIdx.x;
 -  
 -      if (i < 65536)
 -          y[i] = 2.0F * x[i] + y[i];
 -  }
 -  void driver(float *x, float *y)
 -  {
 -      float *d_x, *d_y;
 -  
 -      cudaMalloc(&d_x, 65536 * sizeof(float));
 -      cudaMalloc(&d_y, 65536 * sizeof(float));
 -      cudaMemcpy(d_x, x, 65536, cudaMemcpyHostToDevice);
 -      cudaMemcpy(d_y, y, 65536, cudaMemcpyHostToDevice);
 -      saxpy<<<(65536 + 255) / 256, 256>>>(d_x, d_y);
 -      cudaFree(d_x);
 -      cudaFree(d_y);
 -      return 0;
 -  }
-}

main :: IO ()
main = do
  let ker = makeKernel "saxpy" 2 65536
  mapM_ (putDocLn . ppr) ker

























