import unittest
from pyeloquent.core import example_function

class TestCore(unittest.TestCase):
    def test_example_function(self):
        self.assertEqual(example_function(), "This is an example function.")

if __name__ == "__main__":
    unittest.main()
