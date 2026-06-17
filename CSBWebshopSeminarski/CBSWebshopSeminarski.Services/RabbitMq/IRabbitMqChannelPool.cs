using RabbitMQ.Client;

namespace CBSWebshopSeminarski.Services.RabbitMq;

/// <summary>
/// Pool publish channela na dijeljenoj konekciji — izbjegava otvaranje novog channela po poruci.
/// </summary>
public interface IRabbitMqChannelPool : IDisposable
{
    IModel RentChannel();

    void ReturnChannel(IModel channel);
}
