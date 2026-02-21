const GREEN = "#009110";

const providers = [
  "Venmo",
  "CashApp",
  "Chime",
  "Revolut",
  "Wise",
  "PayPal",
  "Zelle",
];

export default function Home() {
  return (
    <main
      style={{
        maxWidth: 640,
        margin: "4rem auto",
        fontFamily: "system-ui",
        padding: "0 1rem",
      }}
    >
      <h1 style={{ fontSize: "1.5rem", fontWeight: 700, color: GREEN }}>
        Give your Agent Real World Payment
      </h1>
      <p style={{ color: "#666", marginTop: "0.5rem", lineHeight: 1.6 }}>
        Let your Agent use its digital currencies from any major blockchain and
        send <strong style={{ color: GREEN }}>USD</strong> to real people via{" "}
        {providers.map((p, i) => (
          <span key={p}>
            <strong style={{ color: GREEN }}>{p}</strong>
            {i < providers.length - 1 ? ", " : "."}
          </span>
        ))}
      </p>
      <p style={{ color: "#666", marginTop: "0.5rem" }}>
        Powered by{" "}
        <a href="https://daimo.com" style={{ color: GREEN }}>
          Daimo
        </a>{" "}
        and{" "}
        <a href="https://peer.xyz" style={{ color: GREEN }}>
          Peer
        </a>
      </p>

      <h2 style={{ fontSize: "1.1rem", fontWeight: 600, marginTop: "2rem" }}>
        Install
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
        npx skills add daimo-eth/real-world-payment
      </pre>
      <pre
        style={{
          background: "#f5f5f5",
          padding: "1rem",
          borderRadius: 8,
          overflow: "auto",
          fontSize: "0.85rem",
          marginTop: "0.5rem",
        }}
      >
        clawhub install daimo-eth/real-world-payment
      </pre>

      <p style={{ color: "#999", fontSize: "0.8rem", marginTop: "2rem" }}>
        80bps total fee (30bps routing + 50bps market maker) · Minimum $1 ·
        destination USD only
      </p>
    </main>
  );
}
