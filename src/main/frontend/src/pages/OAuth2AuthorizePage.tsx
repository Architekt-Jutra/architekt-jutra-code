import { useEffect, useRef, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { Box, Button, Flex, Heading, Spinner, Text } from "@chakra-ui/react";

const scopeDescriptions: Record<string, { title: string; description: string }> = {
  "mcp:read": {
    title: "Read data",
    description: "View and access your data (always required)",
  },
  "mcp:edit": {
    title: "Edit data",
    description: "Create, modify, and delete your data",
  },
};

const ALWAYS_SELECTED_SCOPES = new Set(["mcp:read"]);

export function OAuth2AuthorizePage() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [clientName, setClientName] = useState("Application");
  const [availableScopes, setAvailableScopes] = useState<string[]>([]);
  const [selectedScopes, setSelectedScopes] = useState<Record<string, boolean>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const fetched = useRef(false);

  const clientId = searchParams.get("client_id") || "";
  const redirectUri = searchParams.get("redirect_uri") || "";
  const responseType = searchParams.get("response_type") || "";
  const scope = searchParams.get("scope") || "";
  const state = searchParams.get("state") || "";
  const codeChallenge = searchParams.get("code_challenge") || "";
  const codeChallengeMethod = searchParams.get("code_challenge_method") || "";

  useEffect(() => {
    if (fetched.current || !clientId) return;
    fetched.current = true;

    fetch(`/api/oauth2/client-info?client_id=${encodeURIComponent(clientId)}`)
      .then((res) => {
        if (!res.ok) throw new Error("Unknown client");
        return res.json();
      })
      .then((data) => {
        setClientName(data.client_name || "Application");
        const clientScopes: string[] = data.scopes || [];
        const requestedScopes = scope.split(" ").filter(Boolean);
        const effective = requestedScopes.length > 0
          ? requestedScopes.filter((s: string) => clientScopes.includes(s))
          : clientScopes;
        setAvailableScopes(effective);
        const initial: Record<string, boolean> = {};
        effective.forEach((s: string) => {
          initial[s] = ALWAYS_SELECTED_SCOPES.has(s) ? true : false;
        });
        setSelectedScopes(initial);
      })
      .catch(() => setError("Failed to load client information"))
      .finally(() => setLoading(false));
  }, [clientId, scope]);

  const atLeastOneSelected = availableScopes.some((s) => selectedScopes[s]);

  function toggleScope(scopeId: string) {
    if (ALWAYS_SELECTED_SCOPES.has(scopeId)) return;
    setSelectedScopes((prev) => ({ ...prev, [scopeId]: !prev[scopeId] }));
  }

  function getSelectedScopesString() {
    return availableScopes.filter((s) => selectedScopes[s]).join(" ");
  }

  function handleCancel() {
    if (redirectUri) {
      const url = new URL(redirectUri);
      url.searchParams.set("error", "access_denied");
      url.searchParams.set("error_description", "User denied authorization");
      if (state) url.searchParams.set("state", state);
      window.location.href = url.toString();
    } else {
      navigate("/products");
    }
  }

  if (loading) {
    return (
      <Flex minH="100vh" align="center" justify="center" bg="#F8FAFC">
        <Spinner size="lg" color="blue.500" />
      </Flex>
    );
  }

  return (
    <Flex minH="100vh" align="center" justify="center" bg="#F8FAFC">
      <Box bg="white" border="1px solid" borderColor="#E2E8F0" borderRadius="12px" p="40px" w="100%" maxW="440px">
        <form method="POST" action="/oauth2/authorize">
          {/* Hidden fields to preserve OAuth parameters */}
          <input type="hidden" name="_token" value={localStorage.getItem("auth_token") || ""} />
          <input type="hidden" name="client_id" value={clientId} />
          <input type="hidden" name="redirect_uri" value={redirectUri} />
          <input type="hidden" name="response_type" value={responseType} />
          <input type="hidden" name="scope" value={getSelectedScopesString()} />
          {state && <input type="hidden" name="state" value={state} />}
          {codeChallenge && <input type="hidden" name="code_challenge" value={codeChallenge} />}
          {codeChallengeMethod && <input type="hidden" name="code_challenge_method" value={codeChallengeMethod} />}

          <Heading as="h1" fontSize="20px" fontWeight="700" color="#0F172A" mb="8px" textAlign="center">
            {clientName}
          </Heading>
          <Text fontSize="14px" color="#64748B" mb="24px" textAlign="center">
            wants to access your account
          </Text>

          {error && (
            <Box mb="16px" p="12px" bg="#FEE2E2" borderRadius="8px" fontSize="13px" color="#991B1B">
              {error}
            </Box>
          )}

          <Text fontSize="13px" fontWeight="500" color="#334155" mb="12px">
            Permissions requested:
          </Text>

          <Box mb="24px">
            {availableScopes.map((scopeId) => {
              const info = scopeDescriptions[scopeId] || { title: scopeId, description: "" };
              const isLocked = ALWAYS_SELECTED_SCOPES.has(scopeId);
              const isSelected = selectedScopes[scopeId];
              return (
                <Box
                  key={scopeId}
                  p="12px"
                  mb="8px"
                  border="1px solid"
                  borderColor={isSelected ? "#3B82F6" : "#E2E8F0"}
                  borderRadius="8px"
                  cursor={isLocked ? "default" : "pointer"}
                  bg={isSelected ? "#EFF6FF" : "white"}
                  opacity={isLocked ? 0.7 : 1}
                  onClick={() => toggleScope(scopeId)}
                  _hover={isLocked ? {} : { borderColor: "#93C5FD" }}
                >
                  <Flex align="center" gap="12px">
                    <Box
                      w="18px" h="18px" borderRadius="4px" flexShrink={0}
                      border="2px solid"
                      borderColor={isSelected ? "#3B82F6" : "#CBD5E1"}
                      bg={isSelected ? "#3B82F6" : "white"}
                      display="flex" alignItems="center" justifyContent="center"
                    >
                      {isSelected && (
                        <Text color="white" fontSize="11px" fontWeight="bold" lineHeight="1">✓</Text>
                      )}
                    </Box>
                    <Box>
                      <Text fontSize="14px" fontWeight="500" color="#0F172A">{info.title}</Text>
                      {info.description && (
                        <Text fontSize="12px" color="#64748B">{info.description}</Text>
                      )}
                    </Box>
                  </Flex>
                </Box>
              );
            })}
          </Box>

          <Flex gap="12px">
            <Button variant="outline" flex="1" type="button" onClick={handleCancel}>
              Cancel
            </Button>
            <Button
              colorPalette="blue" flex="1"
              type="submit"
              disabled={!atLeastOneSelected}
            >
              Allow
            </Button>
          </Flex>

          <Text fontSize="11px" color="#94A3B8" mt="16px" textAlign="center">
            Make sure you trust {clientName}. You may be sharing sensitive info with this application.
          </Text>
        </form>
      </Box>
    </Flex>
  );
}
