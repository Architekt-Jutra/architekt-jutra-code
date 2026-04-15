import { Box, Button, Flex, Heading, Input, Text } from "@chakra-ui/react";
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

export function LoginPage() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await login(username, password);
      navigate("/products", { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setLoading(false);
    }
  }

  return (
    <Flex minH="100vh" align="center" justify="center" bg="#F8FAFC">
      <Box
        bg="white"
        border="1px solid"
        borderColor="#E2E8F0"
        borderRadius="12px"
        p="40px"
        w="100%"
        maxW="400px"
      >
        <Heading as="h1" fontSize="24px" fontWeight="700" color="#0F172A" mb="8px" textAlign="center">
          <Text as="span" color="brand.400">Tomorrow</Text>
          <Text as="span" color="#0F172A" fontWeight="800">Commerce</Text>
        </Heading>
        <Text fontSize="14px" color="#64748B" mb="32px" textAlign="center">
          Sign in to your account
        </Text>

        <form onSubmit={handleSubmit}>
          <Box mb="16px">
            <label htmlFor="username">
              <Text fontSize="14px" fontWeight="500" color="#334155" mb="4px">
                Username
              </Text>
            </label>
            <Input
              id="username"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="Enter username"
              border="1px solid"
              borderColor="#E2E8F0"
              borderRadius="8px"
            />
          </Box>

          <Box mb="24px">
            <label htmlFor="password">
              <Text fontSize="14px" fontWeight="500" color="#334155" mb="4px">
                Password
              </Text>
            </label>
            <Input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Enter password"
              border="1px solid"
              borderColor="#E2E8F0"
              borderRadius="8px"
            />
          </Box>

          {error && (
            <Box mb="16px" p="12px" bg="#FEE2E2" borderRadius="8px" fontSize="13px" color="#991B1B">
              {error}
            </Box>
          )}

          <Button
            type="submit"
            colorPalette="blue"
            w="100%"
            disabled={loading || !username || !password}
          >
            {loading ? "Signing in..." : "Sign In"}
          </Button>
        </form>
      </Box>
    </Flex>
  );
}
