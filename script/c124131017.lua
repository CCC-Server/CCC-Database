--데 리퍼의 공습
local s,id=GetID()
function s.initial_effect(c)
        --Activate
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_ACTIVATE)
        e1:SetCode(EVENT_FREE_CHAIN)
        c:RegisterEffect(e1)
        --tohand
        local e2=Effect.CreateEffect(c)
        e2:SetCategory(CATEGORY_TOGRAVE)
        e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
        e2:SetRange(LOCATION_SZONE)
        e2:SetCode(EVENT_PHASE+PHASE_STANDBY)
        e2:SetHintTiming(TIMING_STANDBY_PHASE,0)
        e2:SetCountLimit(1)
        e2:SetCondition(s.tgcon)
        e2:SetTarget(s.tgtg)
        e2:SetOperation(s.tgop)
        c:RegisterEffect(e2)
    end
    function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
        return Duel.GetTurnPlayer()==tp
    end
    function s.filter(c)
        return c:IsSetCard(0x810) and c:IsType(TYPE_MONSTER) and c:IsAbleToGrave()
    end
    function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
        if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil) end
        Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
    end
    function s.tgop(e,tp,eg,ep,ev,re,r,rp)
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        if not e:GetHandler():IsRelateToEffect(e) then return end
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
        local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK,0,1,2,nil)
        if #g>0 then
            Duel.SendtoHand(g,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,g)
        end
    end

