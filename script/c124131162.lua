--주석의 마법진
local s,id=GetID()
function s.initial_effect(c)
    -- Activate
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DRAW)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

s.listed_series={0x501}
s.listed_names={100000651} -- "연금수-주석의 아에토스" 카드 코드

-- Filter for "연금수-주석의 아에토스"
function s.spfilter1(c,e,tp)
    return c:IsCode(100000651) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- Filter for other "연금수" monsters
function s.spfilter2(c,e,tp)
    return c:IsSetCard(0x501) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) and not c:IsCode(100000651)
end

-- Draw filter
function s.drawfilter(c)
    return c:IsType(TYPE_MONSTER) and c:IsAbleToDraw()
end

-- Target function
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    local b1=Duel.GetLocationCount(tp,LOCATION_MZONE)>1
        and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,nil,e,tp)
        and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,nil,e,tp)
    local b2=Duel.IsPlayerCanDraw(tp,1)
    if chk==0 then return b1 or b2 end
    local ops={}
    local opval={}
    local off=1
    if b1 then
        ops[off]=aux.Stringid(id,0) -- 첫 번째 효과
        opval[off-1]=1
        off=off+1
    end
    if b2 then
        ops[off]=aux.Stringid(id,1) -- 두 번째 효과
        opval[off-1]=2
        off=off+1
    end
    local op=Duel.SelectOption(tp,table.unpack(ops))
    local sel=opval[op]
    if sel==1 then
        e:SetCategory(CATEGORY_SPECIAL_SUMMON)
        e:SetOperation(s.spop)
        s.sptg(e,tp,eg,ep,ev,re,r,rp,1)
    elseif sel==2 then
        e:SetCategory(CATEGORY_DRAW)
        e:SetOperation(s.drawop)
        s.drawtg(e,tp,eg,ep,ev,re,r,rp,1)
    end
end

-- Special summon target function
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetFlagEffect(tp,id)==0 and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,nil,e,tp)
        and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,nil,e,tp) end
    Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_DECK+LOCATION_REMOVED)
end

-- Special summon operation function
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
    local g1=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,1,nil,e,tp)
    local g2=Duel.SelectMatchingCard(tp,s.spfilter2,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,1,nil,e,tp)
    if #g1>0 and #g2>0 then
        Duel.SpecialSummonStep(g1:GetFirst(),0,tp,tp,false,false,POS_FACEUP)
        Duel.SpecialSummonStep(g2:GetFirst(),0,tp,tp,false,false,POS_FACEUP)
        Duel.SpecialSummonComplete()
        -- Restrict special summon from extra deck
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_FIELD)
        e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
        e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
        e1:SetTargetRange(1,0)
        e1:SetTarget(s.splimit)
        e1:SetReset(RESET_PHASE+PHASE_END)
        Duel.RegisterEffect(e1,tp)
    end
end

-- Restriction effect
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
    return c:IsLocation(LOCATION_EXTRA)
end

function s.drawtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,nil)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,1-tp,LOCATION_GRAVE)
end
function s.drawop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,nil)
	if #g>0 then
		local sg=aux.SelectUnselectGroup(g,e,tp,1,3,nil,1,tp,HINTMSG_REMOVE)
		Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
	end
end