import { ALL_PROVIDERS } from "@/lib/constants";

export default function Home() {
  return (
    <main style={{ maxWidth: 640, margin: "4rem auto", fontFamily: "system-ui", padding: "0 1rem" }}>
      <h1 style={{ fontSize: "1.5rem", fontWeight: 700 }}>
        Real World Payment API
      </h1>
      <p style={{ color: "#666", marginTop: "0.5rem" }}>
        Send USD to real people via {ALL_PROVIDERS.length} payment providers.
        Powered by Daimo + Peer Protocol.
      </p>

      <h2 style={{ fontSize: "1.1rem", fontWeight: 600, marginTop: "2rem" }}>
        POST /api/send-payment
      </h2>
      <pre
        style={{
          background: "#f5f5f5",
          padding: "1rem",
          borderRadius: 8,
          overflow: "auto",
          fontSize: "0.85rem",
        }}
      >
        {JSON.stringify(
          {
            provider: "venmo",
            recipient_handle: "@john",
            sender_address: "0x...",
          },
          null,
          2
        )}
      </pre>

      <h2 style={{ fontSize: "1.1rem", fontWeight: 600, marginTop: "2rem" }}>
        GET /api/check-status?sessionId=...
      </h2>
      <p style={{ color: "#666" }}>Poll for settlement status.</p>

      <h2 style={{ fontSize: "1.1rem", fontWeight: 600, marginTop: "2rem" }}>
        Supported providers
      </h2>
      <ul style={{ columns: 2, fontSize: "0.9rem" }}>
        {ALL_PROVIDERS.map((p) => (
          <li key={p}>{p}</li>
        ))}
      </ul>
    </main>
  );
}
